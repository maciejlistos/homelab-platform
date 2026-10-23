{ ... }:
{
  imports = [
    ./wifi.nix
    ./lan.nix
    ./routing.nix
    ./dhcp-dns.nix
    ./tailscale.nix
    ./monitoring.nix
    ./heartbeat.nix
    ./logging.nix
  ];
}
