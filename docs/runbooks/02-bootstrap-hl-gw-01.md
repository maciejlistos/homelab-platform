# Add the `hl-gw-01` hardware configuration

## Purpose

Replace the temporary `hl-gw-01` hardware placeholder with the NixOS hardware
configuration generated on the gateway. This records the boot modules, disk
filesystems, CPU platform, and Intel microcode settings required by the host.

## Prerequisites

- `hl-gw-01` is booted into NixOS or the NixOS installer.
- The repository created in the preceding runbook is available on the host.
- The target root and EFI system partitions have been created and mounted.
- Commands requiring elevated privileges can be run with `sudo`.
- The working directory is the root of the HomeLab repository.

## Procedure

### 1. Generate the host configuration

Scan the mounted system and generate the NixOS configuration:

```bash
sudo nixos-generate-config
```

By default, the generated hardware configuration is written to
`/etc/nixos/hardware-configuration.nix`.

### 2. Review the detected hardware

Inspect the generated file before adding it to the repository:

```bash
sudo less /etc/nixos/hardware-configuration.nix
```

Confirm that the scan detected:

- the kernel modules needed during early boot;
- the root filesystem and its persistent UUID;
- the EFI system partition and its persistent UUID;
- the `x86_64-linux` host platform;
- Intel CPU microcode support.

Do not copy disk identifiers from another machine. They must match the
partitions installed in `hl-gw-01`.

### 3. Replace the repository placeholder

Copy the generated hardware configuration into the host definition:

```bash
sudo cp /etc/nixos/hardware-configuration.nix \
  hosts/hl-gw-01/hardware-configuration.nix
sudo chown "$(id -u):$(id -g)" \
  hosts/hl-gw-01/hardware-configuration.nix
```

This replaces the temporary placeholder created with the initial repository.
Treat the resulting file as generated output; make general host configuration
changes in `hosts/hl-gw-01/default.nix` or an appropriate reusable module.

### 4. Verify the generated settings

For the hardware captured by this runbook, verify that
`hosts/hl-gw-01/hardware-configuration.nix` contains the following settings:

- `installer/scan/not-detected.nix` is imported;
- the initrd loads `ahci`, `xhci_pci`, `usbhid`, `usb_storage`, `sd_mod`, and
  `sdhci_pci` when available;
- the kernel loads `kvm-intel`;
- `/` uses the ext4 filesystem at UUID
  `a1f4de05-cf9e-4205-863b-93aa006f4e45`;
- `/boot` uses the vfat filesystem at UUID `E4B5-0E99`, with
  `fmask=0077` and `dmask=0077`;
- no swap devices are configured;
- the default host platform is `x86_64-linux`;
- Intel microcode updates follow
  `hardware.enableRedistributableFirmware`.

If any disk UUID differs, stop and reconcile it with the output of:

```bash
lsblk --fs
```

The repository must describe the actual target disks, even when their values
differ from those recorded above.

## Validation

Check the formatting of the generated file:

```bash
nixfmt --check hosts/hl-gw-01/hardware-configuration.nix
```

Confirm that both filesystems evaluate to their expected devices:

```bash
nix eval --raw \
  '.#nixosConfigurations.hl-gw-01.config.fileSystems."/".device'
nix eval --raw \
  '.#nixosConfigurations.hl-gw-01.config.fileSystems."/boot".device'
```

Expected output, one value per command:

```text
/dev/disk/by-uuid/a1f4de05-cf9e-4205-863b-93aa006f4e45
/dev/disk/by-uuid/E4B5-0E99
```

Build the system configuration without activating it:

```bash
nix build .#nixosConfigurations.hl-gw-01.config.system.build.toplevel
```

Finally, review the repository changes:

```bash
git diff -- hosts/hl-gw-01/hardware-configuration.nix
git status --short
```

## Result

The `hl-gw-01` host definition contains its generated hardware configuration.
NixOS can discover the required storage during early boot, mount the root and
EFI filesystems by persistent UUID, enable Intel virtualization support, and
apply Intel CPU microcode updates when redistributable firmware is enabled.
