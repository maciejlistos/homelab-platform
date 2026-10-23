# Network and access

```mermaid
flowchart TD
    internet["Internet"] -->|WAN| router["Home Wi-Fi router<br/>no port forwarding<br/>no VLANs assumed"]
    router -->|Wi-Fi uplink, DHCP| gw["hl-gw-01<br/>10.20.0.1/24<br/>NAT · DHCP/DNS lab.home.arpa"]
    gw -->|Ethernet| lan["Lab LAN 10.20.0.0/24<br/>DHCP pool .100–.199<br/>reservations .10 .20 .30"]
    lan --> nodes["Talos nodes<br/>Talos API · Kubernetes API"]
    nodes --> ingress["Tailscale Operator ingresses<br/>Argo CD · Grafana · Forgejo · n8n · …"]

    subgraph tailnet["Tailscale tailnet · private access plane"]
        admin["Admin workstation<br/>NixOS laptop"]
        phone["Phone and other clients"]
    end

    admin -->|subnet route 10.20.0.0/24| gw
    admin -->|HTTPS| ingress
    phone -->|HTTPS| ingress
```

## Rules

| Rule | Why |
| --- | --- |
| No inbound port forwarding on the home router | Nothing in the lab is reachable from the internet |
| Remote access only over Tailscale | One authenticated, encrypted access plane, governed by tailnet ACLs |
| Talos and Kubernetes APIs reached through the gateway's subnet route | Nodes stay off the tailnet; the gateway is the single entry point |
| Applications published with `ingressClassName: tailscale` | Each service gets its own tailnet hostname and TLS certificate |
| Kubernetes admin rights bound to a Tailscale identity | No long-lived kubeconfig credentials have to be handed out for remote use |
| SSH on the gateway: keys only, one admin user, no root login | Smallest useful attack surface |

## Addressing

| Range or host | Use |
| --- | --- |
| `10.20.0.1` | Gateway |
| `10.20.0.10`–`10.20.0.30` | Talos nodes, static DHCP reservations |
| `10.20.0.50` | Forgejo LAN load balancer (Cilium L2 announcement), used by nodes to pull images |
| `10.20.0.100`–`10.20.0.199` | DHCP pool |
