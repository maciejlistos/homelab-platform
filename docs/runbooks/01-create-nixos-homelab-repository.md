# Create the NixOS HomeLab repository

## Purpose

Create the initial declarative NixOS repository for the HomeLab and add the
`hl-gw-01` gateway host. The resulting repository contains reusable common
modules, architecture documentation, and a flake-based NixOS configuration.

## Prerequisites

- Git is installed.
- Nix with flake support is installed for validation.
- The working directory is the root of the HomeLab repository.

## Procedure

### 1. Create the repository layout

Create directories for host-specific configuration, reusable modules, and
operational documentation:

```bash
mkdir -p docs/runbooks hosts/hl-gw-01 modules/common
```

The resulting layout is:

```text
.
├── docs/
│   ├── architecture.md
│   └── runbooks/
├── hosts/
│   └── hl-gw-01/
└── modules/
    └── common/
```

### 2. Add repository ignore rules

Create `.gitignore` and exclude Nix build-result symlinks and direnv state:

```gitignore
# Nix build results
result
result-*

# direnv
.direnv/
```

### 3. Add the repository overview

Create `README.md` with:

- a short description of the declarative HomeLab repository;
- a host inventory containing `hl-gw-01`, its gateway role, and NixOS;
- descriptions of the `hosts/`, `modules/`, and `docs/` directories;
- the planned path from the Internet through the home Wi-Fi router,
  `hl-gw-01`, and the HomeLab switch to the Talos control-plane and worker
  nodes.

Document that `hl-gw-01` routes between the existing Wi-Fi network and the
HomeLab Ethernet network.

### 4. Document the architecture

Create `docs/architecture.md`. Record the current topology and the gateway
hardware and operating system:

```text
Existing home network
        │
  Wi-Fi router
        │ Wi-Fi
        ▼
hl-gw-01 (Dell Wyse 5070, NixOS)
        │ Ethernet
        ▼
      Switch
       ├── Talos control plane
       └── Talos worker
```

### 5. Define the Nix flake

Create `flake.nix` with the HomeLab description and the NixOS 26.05 nixpkgs
input:

```nix
{
  description = "Declarative configuration for the HomeLab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { nixpkgs, ... }:
    {
      nixosConfigurations.hl-gw-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./hosts/hl-gw-01
        ];
      };
    };
}
```

This exposes the host as the `nixosConfigurations.hl-gw-01` flake output.

### 6. Define the `hl-gw-01` host

Create `hosts/hl-gw-01/default.nix` and import both the host hardware file and
the shared common module:

```nix
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
  ];

  networking.hostName = "hl-gw-01";
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocal = "en_US.UTF-8";
  system.stateVersion = "26.05";
}
```

Create `hosts/hl-gw-01/hardware-configuration.nix` as a temporary placeholder:

```nix
{ ... }:
{
  # Temporary placeholder
}
```

Replace this placeholder with the configuration generated on the target host
before deploying the system:

```bash
sudo nixos-generate-config
cp /etc/nixos/hardware-configuration.nix hosts/hl-gw-01/
```

Review the generated file before committing it because disk identifiers and
detected hardware are specific to the target machine.

### 7. Create the common module entry point

Create `modules/common/default.nix` to compose the shared configuration:

```nix
{ ... }:
{
  imports = [
    ./nix.nix
    ./packages.nix
    ./ssh.nix
  ];
}
```

### 8. Configure Nix

Create `modules/common/nix.nix`. Enable the modern Nix CLI and flakes, and
enable automatic Nix store optimisation:

```nix
{ ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.auto-optimise-store = true;
}
```

### 9. Install common administration packages

Create `modules/common/packages.nix` with the baseline command-line and
hardware-diagnostics packages:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    ethtool
    git
    jq
    pciutils
    usbutils
    vim
    neovim
  ];
}
```

### 10. Enable remote administration

Create `modules/common/ssh.nix` and enable the OpenSSH daemon:

```nix
{ ... }:
{
  services.openssh.enable = true;
}
```

This only enables the service. Configure users, SSH public keys, and the
required authentication policy before exposing the host to an untrusted
network.

## Validation

Check that the Nix files use the expected formatting:

```bash
find . -name '*.nix' -print0 | xargs -0 nixfmt --check
```

Confirm that the host output evaluates:

```bash
nix eval .#nixosConfigurations.hl-gw-01.config.networking.hostName
```

Expected result:

```text
"hl-gw-01"
```

Build the system configuration without activating it:

```bash
nix build .#nixosConfigurations.hl-gw-01.config.system.build.toplevel
```

The build creates a `result` symlink, which is ignored by Git. A successful
build confirms that the flake, host configuration, and common module imports
compose correctly; it does not make the placeholder hardware configuration
suitable for deployment.

Finally, review the repository state:

```bash
git status --short
```

## Result

The repository now provides an initial NixOS configuration for `hl-gw-01`,
using NixOS 26.05 on `x86_64-linux`, with shared Nix settings, administration
packages, and OpenSSH enabled. The network gateway and routing configuration
remain future work.
