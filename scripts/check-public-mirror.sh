#!/usr/bin/env bash
# Fail if the working tree contains values that must never be published:
# real tailnet hostnames, SOPS ciphertext, private keys, SSH public keys,
# age recipients or globally unique MAC addresses.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

patterns=(
  '[a-z0-9-]+\.ts\.net'                       # tailnet hostnames other than example.ts.net
  'ENC\[AES256_GCM'                            # SOPS ciphertext
  'BEGIN [A-Z ]*PRIVATE KEY'                   # private keys
  'ssh-(ed25519|rsa) AAAA[0-9A-Za-z+/]{20,}'   # SSH public keys
  'age1[0-9a-z]{58}'                           # real age recipients
  '\b([0-9a-f]{2}:){5}[0-9a-f]{2}\b'           # MAC addresses
)

failed=0
for pattern in "${patterns[@]}"; do
  # Placeholders: example.ts.net and locally administered 02:00:00:* MACs.
  # -P, not -E: the patterns use \b, which macOS's ERE git grep silently never matches.
  if hits="$(git grep -nIiP -e "$pattern" -- . ':!scripts/check-public-mirror.sh' \
      | grep -viE 'example\.ts\.net|02:00:00(:[0-9a-f]{2}){3}')"; then
    echo "Forbidden pattern: ${pattern}"
    echo "${hits}"
    failed=1
  fi
done

if [[ "${failed}" -eq 0 ]]; then
  echo "No forbidden values found."
fi
exit "${failed}"
