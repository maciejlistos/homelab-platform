# Secrets

The private repository keeps every secret in this directory encrypted with
[SOPS](https://github.com/getsops/sops) and [age](https://age-encryption.org/).
This public mirror contains only `*.example.yaml` files that show the expected
keys.

| Example file | Used by | Decrypted by |
| --- | --- | --- |
| `hl-gw-01.example.yaml` | `modules/gateway/wifi.nix`, `modules/gateway/heartbeat.nix` | sops-nix on `hl-gw-01`, with the host SSH key |
| `esphome.example.yaml` | `esphome/hl-ble-proxy-01.yaml` | the operator, only while flashing the device |

Kubernetes Secrets live next to the component that uses them as
`*.sops.yaml` in the private repository, and as `*secret.example.yaml` here.

Recipients are declared in [`.sops.yaml`](../.sops.yaml). Each file is
encrypted for the administrator and, where a host decrypts it, for that host.

```sh
sops edit secrets/hl-gw-01.yaml
sops updatekeys secrets/hl-gw-01.yaml   # after changing recipients
```

CI fails if a file in this directory, `talos/secrets.yaml`, or any
`*.sops.yaml` file is not encrypted.
