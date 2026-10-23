{ ... }:

{
  services.journald.storage = "persistent";

  services.alloy = {
    enable = true;

    extraFlags = [
      "--disable-reporting"
    ];
  };

  environment.etc."alloy/config.alloy".text = ''
    discovery.relabel "journal_common" {
      targets = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }

      rule {
        source_labels = ["__journal_syslog_identifier"]
        target_label  = "syslog_identifier"
      }
    }

    loki.source.journal "alloy" {
      matches = "_SYSTEMD_UNIT=alloy.service"
      max_age = "24h"

      labels = {
        host        = "hl-gw-01",
        environment = "homelab",
        source      = "journald",
        service     = "alloy",
      }

      relabel_rules = discovery.relabel.journal_common.rules

      forward_to = [
        loki.write.homelab.receiver,
      ]
    }

    loki.source.journal "dnsmasq" {
      matches = "_SYSTEMD_UNIT=dnsmasq.service"
      max_age = "24h"

      labels = {
        host        = "hl-gw-01",
        environment = "homelab",
        source      = "journald",
        service     = "dnsmasq",
      }

      relabel_rules = discovery.relabel.journal_common.rules

      forward_to = [
        loki.write.homelab.receiver,
      ]
    }

    loki.source.journal "tailscale" {
      matches = "_SYSTEMD_UNIT=tailscaled.service"
      max_age = "24h"

      labels = {
        host        = "hl-gw-01",
        environment = "homelab",
        source      = "journald",
        service     = "tailscale",
      }

      relabel_rules = discovery.relabel.journal_common.rules

      forward_to = [
        loki.write.homelab.receiver,
      ]
    }

    loki.source.journal "ssh" {
      matches = "_SYSTEMD_UNIT=sshd.service"
      max_age = "24h"

      labels = {
        host        = "hl-gw-01",
        environment = "homelab",
        source      = "journald",
        service     = "ssh",
      }

      relabel_rules = discovery.relabel.journal_common.rules

      forward_to = [
        loki.write.homelab.receiver,
      ]
    }

    loki.source.journal "heartbeat" {
      matches = "_SYSTEMD_UNIT=healthchecks-heartbeat.service"
      max_age = "24h"

      labels = {
        host        = "hl-gw-01",
        environment = "homelab",
        source      = "journald",
        service     = "healthchecks",
      }

      relabel_rules = discovery.relabel.journal_common.rules

      forward_to = [
        loki.write.homelab.receiver,
      ]
    }

    loki.source.journal "wifi" {
      matches = "_SYSTEMD_UNIT=wpa_supplicant-wlp0s12f0.service"
      max_age = "24h"

      labels = {
        host        = "hl-gw-01",
        environment = "homelab",
        source      = "journald",
        service     = "wifi",
      }

      relabel_rules = discovery.relabel.journal_common.rules

      forward_to = [
        loki.write.homelab.receiver,
      ]
    }

    loki.source.journal "nftables" {
      matches = "_SYSTEMD_UNIT=nftables.service"
      max_age = "24h"

      labels = {
        host        = "hl-gw-01",
        environment = "homelab",
        source      = "journald",
        service     = "nftables",
      }

      relabel_rules = discovery.relabel.journal_common.rules

      forward_to = [
        loki.write.homelab.receiver,
      ]
    }

    loki.write "homelab" {
      endpoint {
        url = "https://loki-homelab.example.ts.net/loki/api/v1/push"
      }
    }
  '';
}
