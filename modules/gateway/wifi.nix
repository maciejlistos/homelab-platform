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

      interfaces = [
        "wlp0s12f0"
      ];

      secretsFile = config.sops.templates."wireless.conf".path;

      networks."home-wifi" = {
        pskRaw = "ext:psk_home";
      };
    };

    interfaces."wlp0s12f0".useDHCP = true;
  };
}
