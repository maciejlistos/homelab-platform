# 0002. Cilium as CNI and kube-proxy replacement

- Status: Accepted
- Date: 2026-09
- Supersedes: Flannel, the Talos default CNI

## Context

The cluster started with Talos defaults: Flannel and kube-proxy. Flannel does not enforce NetworkPolicy, so policies for exposed services such as n8n and Forgejo would have been accepted by the API server and then silently ignored. There was also no way to see which flows were being allowed or dropped.

## Decision

Replace Flannel with Cilium, managed by Argo CD, and then replace kube-proxy with Cilium's eBPF service handling. Enable Hubble for flow visibility, and L2 announcements to give LAN-reachable load-balancer addresses.

## Rationale

- NetworkPolicy is enforced, so ingress restrictions actually hold.
- Hubble shows each flow and verdict, which turns policy work from guesswork into evidence: audit first, then enforce.
- L2 announcements remove the need for a separate load-balancer controller.
- One component instead of two for pod networking and service routing.

## Consequences

- The migration needed a planned outage while pods moved to the new CNI. It was run as a maintenance window with backups taken first and stateful apps stopped deliberately.
- Talos must be configured with no built-in CNI and kube-proxy disabled (`cluster.network.cni: none`, `cluster.proxy.disabled: true`), so a fresh cluster is not functional until Cilium is installed.
- Cilium upgrades are now a platform-critical change and are tested before they are rolled out.
