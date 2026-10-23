# HomeLab change workflow

1. Create a branch from main.
2. Commit changes and push the branch.
3. Open a pull request targeting main.
4. Wait for the required `CI / Result` check to pass.
5. Merge the pull request.
6. Verify Argo CD synchronization and application health.

`.forgejo/workflows/ci.yaml` runs only the checks relevant to the changed paths.
Manual runs, new branches and changes to the workflow itself run every check.

| Job | Runs when these paths change | Blocking |
| --- | --- | --- |
| Kyverno policies | `policies/kyverno/`, `tests/kyverno/`, Home Assistant and Forgejo runner Deployments | yes |
| n8n chart audit | `policies/kyverno/`, n8n Application and values, `scripts/render-n8n.nu`, `flake.*` | no (audit only) |
| TrailLog generated quota | `kubernetes/apps/traillog/kcl/`, `kubernetes/apps/traillog/generated/` | yes |
| NixOS evaluation | `flake.*`, `hosts/`, `modules/`, `keys/`, `secrets/hl-gw-01.yaml` | yes |
| SOPS encryption guard | `.sops.yaml`, `secrets/`, `talos/secrets.yaml`, `*.sops.yaml`, `kubernetes/` | yes |

Mark only `CI / Result` as required in branch protection. It passes when every
other job either succeeded or was skipped, so path-filtered jobs never block a
merge by not running.

Talos patches, ESPHome and most Kubernetes manifests are not yet validated in CI.
