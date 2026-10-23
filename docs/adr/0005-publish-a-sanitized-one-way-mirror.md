# 0005. Publish a sanitized one-way mirror

- Status: Accepted
- Date: 2026-10-23

## Context

The platform repository is the operational source of truth. It contains SOPS ciphertext for real systems, Talos cluster secrets, tailnet hostnames, hardware identifiers and a Git history that may hold old mistakes. I also want the work to be visible publicly.

## Decision

Keep the operational repository private. Publish this repository as a curated, one-way export of committed files:

1. Copy only committed files from the private `main` branch.
2. Drop secrets and private-only files, and apply a redaction map, which itself stays private.
3. Refuse to write the export while any forbidden pattern remains.
4. Scan the result with gitleaks and `scripts/check-public-mirror.sh` in CI.
5. Review the diff and commit by hand, with fresh history. Nothing is pushed automatically.

## Rationale

- Making the private repository public would publish its full history, which cannot be audited with certainty.
- A one-way export keeps a single source of truth, so the mirror never needs to be merged back.
- Automated checks before and after the export catch regressions in the redaction map.

## Consequences

- The mirror lags behind the private repository and is refreshed deliberately.
- Some files differ from the private ones (example secrets, placeholder recipients, a public CI workflow). These are owned by the mirror and never overwritten by the export.
- The mirror is not directly deployable. That is intended.
