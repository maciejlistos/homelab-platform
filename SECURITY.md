# Security

## About this mirror

This repository is a sanitized public mirror of a private infrastructure
repository. It is published to show architecture, GitOps layout, policy
checks and operating practice. It is not a deployable copy of a live system.

| Area | In this mirror |
| --- | --- |
| Secrets (SOPS-encrypted in the private repository) | Example files with `CHANGE_ME` placeholders |
| Talos cluster secrets and generated configs | Omitted |
| SOPS recipients | Placeholders |
| Tailscale hostnames | `*.example.ts.net` |
| SSH public keys | Omitted |
| MAC addresses, disk serials, registry CA | Locally administered or obviously fake values |
| Lab addressing (`10.20.0.0/24`) | Kept: a private RFC 1918 range with no route from the internet |
| Git history | Fresh; the private history is not published |

The mirror is produced by a one-way export that copies only committed files,
applies a redaction map, and refuses to write while any forbidden value
remains. CI then runs gitleaks and `scripts/check-public-mirror.sh` on every
push.

## Reporting a problem

If you find something here that looks like a real credential, endpoint or
personal identifier, please open a
[private security advisory](https://github.com/maciejlistos/homelab-platform/security/advisories/new)
rather than a public issue. I will rotate anything affected and fix the
export.
