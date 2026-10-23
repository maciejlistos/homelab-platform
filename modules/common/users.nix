{ ... }:
{
  users.users.admin = {
    isNormalUser = true;

    description = "HomeLab administrator";

    extraGroups = [
      "wheel"
    ];

    openssh.authorizedKeys.keyFiles = [
      ../../keys/admin.example.pub
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
