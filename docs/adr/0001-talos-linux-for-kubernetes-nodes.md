# 0001. Talos Linux for the Kubernetes nodes

- Status: Accepted
- Date: 2026-09

## Context

The cluster runs on three small second-hand mini PCs. A general-purpose distribution plus kubeadm would mean maintaining packages, SSH access, users and drift on every node, by hand or with another configuration tool. The nodes should be cattle: rebuildable from Git in minutes.

## Decision

Run every Kubernetes node on Talos Linux, pinned to an exact version (`talos/VERSION`), installed from an Image Factory schematic that adds `iscsi-tools` and `util-linux-tools` for Longhorn. Node configuration lives in per-node machine-config patches under `talos/patches/`.

## Rationale

- Immutable, minimal OS with no shell or SSH: the only way to change a node is the authenticated Talos API, which makes configuration drift structurally hard.
- The whole node definition is a YAML document, so it fits the same review and Git workflow as the rest of the platform.
- Upgrades are atomic image swaps with rollback, rather than package upgrades.
- Adding the Longhorn extensions at install time avoided rebuilding the nodes later.

## Consequences

- Debugging uses `talosctl` (logs, dmesg, services, containers) instead of SSH. That is a learning cost, and it is also good practice for production clusters where SSH is unavailable.
- Cluster secrets and generated configs grant full access. They are SOPS-encrypted or git-ignored, never committed in plaintext.
- Hardware-specific values (install disk, user volumes) live in per-node patches and must be updated when hardware changes.
