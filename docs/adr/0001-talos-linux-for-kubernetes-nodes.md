# 0001. Talos Linux for the Kubernetes nodes

- Status: Accepted
- Date: 2026-09

## Context

The cluster runs on small, low-power PCs on a private lab LAN behind the NixOS gateway. It started with one control plane and one worker, and a second worker was added later. Each node needs a Kubernetes-ready OS that can be rebuilt from configuration kept in Git, and Longhorn needs iSCSI and util-linux tools on every node.

## Decision

Run every Kubernetes node on Talos Linux:

- pinned to one version for the whole cluster (`talos/VERSION`);
- installed from an Image Factory schematic that adds `iscsi-tools` and `util-linux-tools` (`talos/image-factory/`);
- configured through per-node machine-config patches (`talos/patches/`), applied with `talosctl`.

## Rationale

- I wanted an immutable Linux distribution for the nodes. Talos is built only to run Kubernetes: the root filesystem is read-only and there is no package manager, so a node is exactly what its image and machine config say it is.
- Talos has no SSH and no shell. Every change goes through the authenticated Talos API, so there is no way to hand-edit a node and forget about it.
- A node is defined by its machine config, a YAML document that is reviewed and versioned like the rest of the platform.
- Longhorn was planned from the start, so its extensions went into the first install. Booting an ISO with extensions is not enough: the installer image written to disk must contain them too, which is what the Image Factory schematic provides.

## Consequences

- Troubleshooting uses `talosctl` (logs, dmesg, services, dashboard) instead of SSH.
- The Talos root secrets and generated configs give full control of the cluster. They are never committed in plaintext.
- There is a single control-plane node, so the Kubernetes API and etcd are not highly available. If `talos-cp-01` is down, nothing can be scheduled or changed, although running workloads continue. Three control-plane nodes would fix this; it is not worth the hardware yet.
- Disk selectors and user volumes are hardware-specific and live in each node's patch. New hardware gets its own patch, checked against the real disks.
- All nodes run the same Talos and Kubernetes versions. A new node joins at the cluster's current versions, and upgrades are done for the whole cluster.
