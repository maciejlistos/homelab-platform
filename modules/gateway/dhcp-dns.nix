{ ... }:
{
  services.dnsmasq = {
    enable = true;

    settings = {
      interface = [
        "lo"
        "enp1s0"
      ];

      bind-dynamic = true;

      dhcp-range = [
        "10.20.0.100,10.20.0.199,255.255.255.0,12h"
      ];

      dhcp-host = [
        "02:00:00:00:00:10,id:*,10.20.0.10,talos-cp-01,infinite"
        "02:00:00:00:00:20,id:*,10.20.0.20,talos-worker-01,infinite"
        "02:00:00:00:00:30,id:*,10.20.0.30,talos-worker-02,infinite"
      ];

      dhcp-option = [
        "option:router,10.20.0.1"
        "option:dns-server,10.20.0.1"
      ];

      dhcp-authoritative = true;

      domain = "lab.home.arpa";
      local = "/lab.home.arpa/";
      expand-hosts = true;

      domain-needed = true;
      bogus-priv = true;
    };
  };

  networking.firewall.interfaces.enp1s0 = {
    allowedUDPPorts = [
      53
      67
    ];

    allowedTCPPorts = [
      53
    ];
  };
}
