# Configure Wi-Fi and SOPS on `hl-gw-01`

## Purpose

Connect `hl-gw-01` to the existing home Wi-Fi network through
`wlp0s12f0`, while keeping the Wi-Fi pre-shared key encrypted in the
repository. The configuration uses `sops-nix` to decrypt the secret during
NixOS activation and render a root-readable `wpa_supplicant` secrets file.

## Prerequisites

- The HomeLab repository is available on the administration workstation and
  on `hl-gw-01`.
- `sops` and `age` are installed on the workstation used to edit secrets.
- The workstation has an age identity corresponding to one of the recipients
  in `.sops.yaml`.
- `hl-gw-01` has an Ed25519 SSH host key at
  `/etc/ssh/ssh_host_ed25519_key`.
- The Wi-Fi interface on the gateway is named `wlp0s12f0`.
- The working directory is the root of the HomeLab repository.

Do not commit a plaintext Wi-Fi password or an age private key.

## Procedure

### 1. Identify the SOPS recipients

Derive the gateway's age recipient from its SSH host public key:

```bash
ssh-keyscan -t ed25519 hl-gw-01 2>/dev/null \
  | ssh-to-age
```

Alternatively, run the conversion directly on the gateway:

```bash
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

Obtain the age recipient for the administrator identity as well:

```bash
age-keygen -y ~/.config/sops/age/keys.txt
```

Keep the corresponding private identities outside the repository. The host
recipient permits activation-time decryption on `hl-gw-01`; the administrator
recipient permits maintenance of the encrypted file.

### 2. Define the encryption policy

Create `.sops.yaml` with a rule restricted to the gateway secret file:

```yaml
creation_rules:
  - path_regex: secrets/hl-gw-01\.yaml$
    key_groups:
      - age:
          - <gateway-age-recipient>
          - <administrator-age-recipient>
```

Replace the placeholders with the public recipients identified above. Keeping
both recipients in the same key group means either corresponding private key
can decrypt the file.

### 3. Create the encrypted Wi-Fi secret

Create the secrets directory and open the host secret through SOPS:

```bash
mkdir -p secrets
sops secrets/hl-gw-01.yaml
```

Add the Wi-Fi pre-shared key under the name expected by the NixOS module:

```yaml
wifi_psk: <plaintext-wifi-password>
```

Save and close the editor. SOPS encrypts the value before writing the file.
Confirm that no plaintext password remains:

```bash
sops filestatus secrets/hl-gw-01.yaml
```

The file must report that it is encrypted. Review it before staging and verify
that `wifi_psk` has an `ENC[...]` value.

### 4. Add `sops-nix` to the flake

Add `sops-nix` as an input that follows the repository's nixpkgs input:

```nix
sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Accept `sops-nix` in the flake outputs and add its NixOS module to
`hl-gw-01`:

```nix
outputs =
  { nixpkgs, sops-nix, ... }:
  {
    nixosConfigurations.hl-gw-01 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./hosts/hl-gw-01
        sops-nix.nixosModules.sops
      ];
    };
  };
```

Update and commit `flake.lock` together with this input change:

```bash
nix flake lock
```

### 5. Configure the gateway Wi-Fi module

Create `modules/gateway/wifi.nix`. Configure SOPS to read the encrypted host
file and use the gateway SSH host key as its age identity:

```nix
{ config, ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/hl-gw-01.example.yaml;
    # Public mirror: the private repository uses a SOPS-encrypted file here.
    validateSopsFiles = false;

    age.sshKeyPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    secrets.wifi_psk = { };

    templates."wireless.conf" = {
      owner = "wpa_supplicant";
      group = "wpa_supplicant";
      mode = "0400";

      content = ''
        psk_home=${config.sops.placeholder.wifi_psk}
      '';
    };
  };

  networking = {
    wireless = {
      enable = true;
      interfaces = [ "wlp0s12f0" ];
      secretsFile = config.sops.templates."wireless.conf".path;

      networks."home-wifi" = {
        pskRaw = "ext:psk_home";
      };
    };

    interfaces."wlp0s12f0".useDHCP = true;
  };
}
```

The generated template contains an `ext:` value consumed by
`wpa_supplicant`. Its ownership and mode prevent ordinary users from reading
the decrypted password. The Wi-Fi interface obtains its upstream address by
DHCP.

### 6. Import the gateway module

Create `modules/gateway/default.nix` as the gateway module entry point:

```nix
{ ... }:
{
  imports = [
    ./wifi.nix
  ];
}
```

Import it from `hosts/hl-gw-01/default.nix`:

```nix
imports = [
  ./hardware-configuration.nix
  ../../modules/common
  ../../modules/gateway
];
```

### 7. Permit trusted flake deployments

Add the `wheel` group to `nix.settings.trusted-users` in
`modules/common/nix.nix`:

```nix
nix.settings = {
  experimental-features = [
    "nix-command"
    "flakes"
  ];

  auto-optimise-store = true;
  trusted-users = [ "@wheel" ];
};
```

Only place trusted administrators in `wheel`: trusted Nix users can influence
daemon builds with privileges equivalent to root.

### 8. Deploy the configuration

Before switching, ensure that the gateway host private key still matches the
recipient stored in `.sops.yaml`. Replacing the SSH host key without rotating
the SOPS recipient prevents secret decryption.

Build and activate the configuration on the gateway:

```bash
sudo nixos-rebuild switch --flake .#hl-gw-01
```

Keep an existing local or Ethernet administration session open while testing
Wi-Fi so that a failed wireless configuration does not remove access to the
host.

## Secret maintenance

Edit the Wi-Fi password only through SOPS:

```bash
sops secrets/hl-gw-01.yaml
```

After changing the recipients in `.sops.yaml`, re-encrypt the existing file so
its metadata uses the new recipient set:

```bash
sops updatekeys secrets/hl-gw-01.yaml
```

Then rebuild the gateway. Never edit the encrypted payload or SOPS metadata by
hand.

## Validation

Check Nix formatting and flake metadata:

```bash
nixfmt --check flake.nix hosts/hl-gw-01/default.nix \
  modules/common/nix.nix modules/gateway/default.nix \
  modules/gateway/wifi.nix
nix flake check
```

Build the system without activating it:

```bash
nix build .#nixosConfigurations.hl-gw-01.config.system.build.toplevel
```

On `hl-gw-01`, confirm that the wireless service is running, the interface has
an address, and the default route is present:

```bash
systemctl status wpa_supplicant-wlp0s12f0.service
ip address show dev wlp0s12f0
ip route show default
```

Confirm that the generated secrets file is not world-readable without printing
its contents:

```bash
sudo stat -c '%U %G %a %n' /run/secrets-rendered/wireless.conf
```

Expected ownership and mode are `wpa_supplicant wpa_supplicant 400`. The exact
runtime path can be confirmed with:

```bash
sudo systemctl cat wpa_supplicant-wlp0s12f0.service
```

Finally, verify upstream connectivity:

```bash
ping -c 3 1.1.1.1
getent hosts cache.nixos.org
```

## Troubleshooting

- If activation reports that it cannot decrypt `wifi_psk`, compare the age
  recipient derived from `/etc/ssh/ssh_host_ed25519_key.pub` with the gateway
  recipient in `.sops.yaml`, then run `sops updatekeys` if necessary.
- If the wireless service reports an authentication failure, confirm the SSID
  and edit `wifi_psk` through SOPS. Do not inspect the rendered secret in logs
  or paste it into the shell.
- If `wlp0s12f0` does not exist, use `ip link` to identify the persistent
  interface name and update both occurrences in the module.
- If Wi-Fi associates but no route appears, inspect DHCP messages with
  `journalctl -u systemd-networkd` and the wireless service journal.

## Result

`hl-gw-01` connects to `home-wifi` through `wlp0s12f0` and receives its
upstream network configuration by DHCP. The Wi-Fi key remains encrypted in
Git, is decrypted from the gateway's SSH host identity during activation, and
is exposed to `wpa_supplicant` only through a mode `0400` runtime file.
