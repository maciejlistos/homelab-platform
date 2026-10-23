{ config, pkgs, ... }:
{
  users = {
    groups.healthchecks-heartbeat = { };
    users.healthchecks-heartbeat = {
      isSystemUser = true;
      group = "healthchecks-heartbeat";
    };
  };

  sops.secrets.healthchecks_ping_url = {
    owner = "healthchecks-heartbeat";
    group = "healthchecks-heartbeat";
    mode = "0400";
  };

  systemd.services.healthchecks-heartbeat = {
    description = "Send HomeLab heartbeat to Healthchecks.io";

    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";

      User = "healthchecks-heartbeat";
      Group = "healthchecks-heartbeat";

      ExecStart = ''
        ${pkgs.wget}/bin/wget \
          --quiet \
          --timeout=10 \
          --tries=3 \
          --output-document=/dev/null \
          --input-file=${config.sops.secrets.healthchecks_ping_url.path}
      '';

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  systemd.timers.healthchecks-heartbeat = {
    description = "Run HomeLab external heartbeat";

    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "5m";
      AccuracySec = "15s";
      Persistent = true;
    };
  };
}
