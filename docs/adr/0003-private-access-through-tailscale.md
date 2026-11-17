# 0003. Private access through Tailscale, no port forwarding

- Status: Accepted
- Date: 2026-09

## Context

The platform needs remote administration (the Talos API, the Kubernetes API and SSH to the gateway) and access to its web services from a laptop and a phone, both at home and away. Port forwarding on the home router would put those services on the internet, and it would depend on router settings that are not in Git.

## Decision

- No inbound port forwarding on the home router.
- Web services are published to the tailnet by the Tailscale Kubernetes Operator, one `Ingress` with `ingressClassName: tailscale` per service, each with its own hostname and TLS certificate.
- `kubectl` goes through the operator's Kubernetes API proxy in authenticated mode. The proxy identifies the caller by their Tailscale identity, and Kubernetes RBAC decides what that identity may do.
- `talosctl` goes through the gateway, which advertises the lab LAN as a Tailscale subnet route. The tailnet policy allows only the Talos API port (TCP 50000) through that route, not the whole subnet.
- The Talos nodes are not tailnet clients.

## Rationale

- Nothing is reachable from the internet. Tailscale ingress stays private to the tailnet unless Funnel is explicitly enabled.
- Access is per user and per device, and it is decided by the tailnet policy and Kubernetes RBAC rather than by router rules or a shared admin certificate.
- Publishing a new service is a reviewed `Ingress` in Git, not a manual router change.

## Consequences

- Remote access depends on Tailscale, and the `kubectl` path also depends on the cluster's own networking, because the API proxy runs in the cluster. A direct path to the API server through the gateway, using the Talos-generated kubeconfig, is kept for break-glass access, and changes that risk cluster networking are planned with that path in place.
- The nodes cannot resolve or reach tailnet-only names. Pulling images from the in-cluster Forgejo registry therefore uses a LAN load-balancer address and an explicit registry CA in the Talos config, not the registry's tailnet hostname.
- Making a service public would need a separate design, such as Funnel or a dedicated ingress, with its own threat model.
