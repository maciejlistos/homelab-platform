# Storage and data flow

```mermaid
flowchart TD
    subgraph cluster["Talos Kubernetes cluster"]
        apps["Stateful apps<br/>Forgejo · Home Assistant · n8n<br/>TrailLog · monitoring · logging"]
        lh["Longhorn<br/>replicated block volumes"]
        apps -->|PVCs| lh
    end

    lh --> d1["talos-cp-01<br/>128 GB SATA SSD"]
    lh --> d2["talos-worker-01<br/>1 TB USB SSD"]
    lh --> d3["talos-worker-02<br/>NVMe user volume"]

    subgraph traillog["TrailLog backups"]
        db["SQLite database volume"] -->|online backup, verified| bk["Backup volume"]
        bk -->|tested restore Job| db
    end

    lh -.-> traillog

    lh -->|"replication is availability,<br/>not backup"| offsite["Independent backup target<br/>planned"]
    data["hl-data-01 · planned<br/>NixOS data host<br/>SMB share · future PostgreSQL"] -.-> offsite
```

## Principles

- **Replication is not backup.** Longhorn keeps replicas on different nodes, which survives a node failure, but not deletion, corruption or a bad change.
- **Backups count once restored.** Each backup path needs a restore test before the data it protects is considered safe.
- **Same-disk copies are not backups.** A copy on the same SSD fails with that SSD.
- **Stateful changes start with a recovery plan.** Check backups and know the rollback before changing a persistent workload.

## Current and planned

| Item | State |
| --- | --- |
| Longhorn on dedicated user volumes on all three nodes | Running |
| TrailLog SQLite backup sidecar, verification and restore Job | Running |
| Consistent SQLite backups as a Kubernetes operator | sqlite-backup-operator (In progress) |
| `hl-data-01` NixOS data host with an SMB share | Planned |
| Independent off-cluster backup target | Planned |
