# 0003. Private access through Tailscale, no port forwarding

- Status: Accepted
- Date: 2026-09

## Context

The platform needs remote administration (Talos API, Kubernetes API, SSH to the gateway) and access to its web services from a laptop and a phone, from inside and outside the home. Port forwarding on the home router would expose services to the internet and depend on router configuration that is not under version control.

## Decision

- No inbound port forwarding on the home router.
- The gateway runs Tailscale and advertises the lab LAN as a subnet route; the Talos nodes stay off the tailnet.
- Web services are published to the tailnet with the Tailscale Kubernetes Operator (`ingressClassName: tailscale`), each with its own hostname and TLS certificate.
- Kubernetes admin access is bound to a Tailscale identity.

## Rationale

- Nothing is reachable from the internet, which removes a whole class of risk for a home environment.
- Access is authenticated per device and user, encrypted, and governed by tailnet ACLs rather than by router rules.
- Publishing a new service is a declarative `Ingress` in Git, not a manual router change.

## Consequences

- Access depends on Tailscale's coordination service. Local console access to the gateway is the fallback.
- Nodes are not tailnet clients, so they cannot resolve or reach tailnet-only names. Pulling images from the in-cluster Forgejo registry therefore uses a LAN load-balancer address and an explicit registry CA in the Talos config.
- Making a service public would need a separate design, such as Tailscale Funnel or a dedicated ingress, with its own threat model.
