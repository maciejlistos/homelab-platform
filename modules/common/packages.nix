{ pkgs, ... }:
{
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
}
