{ ... }:
{
  services.tailscale = {
    enable = true;

    openFirewall = true;

    useRoutingFeatures = "server";

    extraUpFlags = [
      "--hostname=hl-gw-01"
      "--advertise-routes=10.20.0.0/24"
      "--accept-dns=false"
      "--ssh"
    ];

    extraSetFlags = [
      "--advertise-routes=10.20.0.0/24"
      "--accept-dns=false"
      "--ssh"
    ];
  };
}
