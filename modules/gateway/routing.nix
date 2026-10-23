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
        # HomeLab -> Wi-Fi / Internet
        iifname "enp1s0" oifname "wlp0s12f0" ip saddr 10.20.0.0/24 accept

        # Tailscale -> HomeLab
        iifname "tailscale0" oifname "enp1s0" ip daddr 10.20.0.0/24 accept

        # Wi-Fi -> HomeLab (for debugging only)
        # iifname "wlp0s12f0" oifname "enp1s0" ip daddr 10.20.0.0/24 accept

      '';
    };
  };
}
