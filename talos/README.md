# Talos Linux

Configuration for the three Talos Linux nodes.

| Path | Purpose |
| --- | --- |
| `VERSION` | Talos version every node runs |
| `image-factory/schematic.yaml` | [Image Factory](https://factory.talos.dev/) schematic: adds `iscsi-tools` and `util-linux-tools` for Longhorn |
| `image-factory/schematic-id` | ID of that schematic, used in the installer image reference |
| `patches/<node>.yaml` | Per-node machine-config patches: hostname, install disk, Longhorn user volume, kubelet mounts, registry trust |

Cluster-wide settings live in the control-plane patch: no built-in CNI and no
kube-proxy, because Cilium replaces both, and control-plane metrics bound to
all interfaces so that Prometheus can scrape them.

## Generating machine configs

The cluster secrets bundle (`talos/secrets.yaml`) is SOPS-encrypted in the
private repository and omitted here. Generated configs and the `talosconfig`
grant full cluster access, so they are written to the git-ignored
`talos/generated/` directory and never committed.

```sh
talosctl gen secrets -o talos/secrets.yaml          # once, then encrypt with SOPS
talosctl gen config homelab https://10.20.0.10:6443 \
  --with-secrets talos/secrets.yaml \
  --config-patch-control-plane @talos/patches/talos-cp-01.yaml \
  --output talos/generated/
talosctl apply-config --nodes 10.20.0.10 --file talos/generated/controlplane.yaml
```

Workers are generated the same way with their own patch. Disk serials,
registry CA and hostnames in this mirror are placeholders.
