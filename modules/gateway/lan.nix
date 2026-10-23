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
