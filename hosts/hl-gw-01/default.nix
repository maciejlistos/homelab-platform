{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/gateway
  ];

  networking.hostName = "hl-gw-01";

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_US.UTF-8";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  system.stateVersion = "26.05";
}
