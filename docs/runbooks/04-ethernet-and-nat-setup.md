# Configure Ethernet routing and NAT on `hl-gw-01`

## Purpose

Configure `hl-gw-01` as the IPv4 gateway for the HomeLab Ethernet network.
The gateway uses `10.20.0.1/24` on `enp1s0`, forwards HomeLab traffic to the
Wi-Fi uplink on `wlp0s12f0`, and applies source NAT so that clients can reach
the existing home network and the Internet.

This runbook does not configure DHCP or DNS on the HomeLab LAN. Use a static
address when validating the first Ethernet client.

## Prerequisites

- The Wi-Fi and SOPS configuration from the preceding runbook is deployed.
- `wlp0s12f0` is connected to the upstream Wi-Fi network and has a default
  route.
- The gateway's Ethernet interface is named `enp1s0`.
- The HomeLab switch or a test client is connected to `enp1s0`.
- The working directory is the root of the HomeLab repository.
- Local console access is available in case a networking change interrupts
  remote administration.

Confirm the interface names before applying the configuration:

```bash
ip -brief link
```

If the names differ, use the names reported on `hl-gw-01` consistently in the
modules below.

## Procedure

### 1. Configure the HomeLab LAN interface

Create `modules/gateway/lan.nix` and assign the gateway address to the
Ethernet interface:

```nix
{ ... }:
{
  networking.interfaces.enp1s0 = {
    useDHCP = false;

    ipv4.addresses = [
      {
        address = "10.20.0.1";
        prefixLength = 24;
      }
    ];
  };
}
```

Disabling DHCP on this interface prevents the gateway from trying to obtain
its LAN address from another device. The `/24` prefix reserves
`10.20.0.0/24` for HomeLab clients; do not assign the network address
`10.20.0.0`, the gateway address `10.20.0.1`, or the broadcast address
`10.20.0.255` to a client.

### 2. Enable routing, NAT, and forwarding

Create `modules/gateway/routing.nix`:

```nix
{ ... }:
{
  networking = {
    nftables.enable = true;

    nat = {
      enable = true;
      externalInterface = "wlp0s12f0";

      internalInterfaces = [
        "enp1s0"
      ];
    };

    firewall = {
      filterForward = true;

      extraForwardRules = ''
        iifname "enp1s0" oifname "wlp0s12f0" ip saddr 10.20.0.0/24 accept
      '';
    };
  };
}
```

`networking.nat` enables IPv4 forwarding and masquerades packets leaving the
Wi-Fi interface. Forward filtering remains enabled, and the additional rule
permits only packets originating from the HomeLab subnet to start traversing
from the LAN to the Wi-Fi uplink. The stateful firewall permits the associated
reply traffic.

### 3. Import the LAN and routing modules

Extend `modules/gateway/default.nix` so the gateway configuration includes
both new modules:

```nix
{ ... }:
{
  imports = [
    ./wifi.nix
    ./lan.nix
    ./routing.nix
  ];
}
```

### 4. Install packet-capture tooling

Add `tcpdump` to `environment.systemPackages` in
`modules/common/packages.nix`:

```nix
environment.systemPackages = with pkgs; [
  curl
  ethtool
  git
  jq
  pciutils
  tcpdump
  usbutils
  vim
  neovim
];
```

Use packet capture only for troubleshooting. Captures can contain sensitive
traffic and should not be committed to the repository.

### 5. Build and deploy the gateway

Check and build the complete configuration before activation:

```bash
nixfmt --check modules/common/packages.nix modules/gateway/default.nix \
  modules/gateway/lan.nix modules/gateway/routing.nix
nix flake check
nix build .#nixosConfigurations.hl-gw-01.config.system.build.toplevel
```

Deploy from `hl-gw-01`:

```bash
sudo nixos-rebuild switch --flake .#hl-gw-01
```

Keep a console or existing administration session open until the LAN and
uplink checks below pass.

### 6. Configure a test client

Connect a client to the HomeLab switch or directly to `enp1s0` and configure
an unused static address. For example:

```text
IPv4 address: 10.20.0.2
Prefix length: 24
Gateway:       10.20.0.1
DNS server:    1.1.1.1
```

These settings are for initial validation. Add a DHCP and DNS service before
expecting clients to configure themselves automatically.

## Validation

On `hl-gw-01`, verify the addresses and routes:

```bash
ip -brief address show dev enp1s0
ip -brief address show dev wlp0s12f0
ip route show
```

`enp1s0` must show `10.20.0.1/24`, while `wlp0s12f0` must have an upstream
address and a default route.

Confirm that IPv4 forwarding is active and inspect the generated firewall and
NAT rules:

```bash
sysctl net.ipv4.ip_forward
sudo nft list ruleset
```

The sysctl must report `net.ipv4.ip_forward = 1`. In the nftables output,
confirm that forwarding from `10.20.0.0/24` on `enp1s0` to `wlp0s12f0` is
accepted and that outbound traffic is masqueraded. Generated table and chain
names may vary between NixOS versions.

From the statically configured client, test each layer in order:

```bash
ping -c 3 10.20.0.1
ping -c 3 1.1.1.1
getent hosts cache.nixos.org
```

The first command validates the Ethernet link and LAN addressing, the second
validates forwarding and NAT, and the third validates the client's configured
DNS resolver.

## Troubleshooting

- If `enp1s0` has no carrier, check the cable and switch port, then inspect
  `ip link show dev enp1s0` and `ethtool enp1s0`.
- If the client cannot reach `10.20.0.1`, verify its address and `/24` prefix,
  and ensure no other device uses the same address.
- If the gateway is reachable but `1.1.1.1` is not, confirm the Wi-Fi default
  route, `net.ipv4.ip_forward`, and the nftables forward and masquerade rules.
- If IP connectivity works but names do not resolve, verify the DNS server on
  the client. The gateway does not provide DNS in this configuration.
- To determine where packets stop, capture only the relevant ICMP traffic on
  each interface in separate terminals:

  ```bash
  sudo tcpdump -ni enp1s0 icmp
  sudo tcpdump -ni wlp0s12f0 icmp
  ```

  Stop each capture with `Ctrl-C` after the test.

## Result

`hl-gw-01` uses `10.20.0.1/24` as the HomeLab LAN gateway. Traffic sourced
from `10.20.0.0/24` can be forwarded from `enp1s0` through the Wi-Fi uplink on
`wlp0s12f0` and is source-NATed for access to the upstream network. HomeLab
clients still require static network settings until DHCP and DNS services are
added.
