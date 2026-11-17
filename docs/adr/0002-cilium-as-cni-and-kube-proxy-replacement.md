# 0002. Cilium as CNI and kube-proxy replacement

- Status: Accepted
- Date: 2026-09-22 (Cilium), 2026-10-14 (kube-proxy replacement)
- Supersedes: Flannel, the Talos default CNI

## Context

The cluster started with the Talos defaults: Flannel and kube-proxy. The next phase of the platform was guardrails: first see which services talk to each other, then restrict that traffic with network policies. Flannel cannot do either. It does not enforce NetworkPolicy, so a policy is accepted by the API server and then has no effect, and it gives no view of the traffic.

## Decision

Move to Cilium in small steps, each verified before the next:

1. Replace Flannel with Cilium in a maintenance window. Keep kube-proxy and leave policy enforcement off, so that only one thing changes.
2. Enable Hubble for flow visibility.
3. Turn on policy audit mode, prove enforcement with a disposable test application, check the real workloads' flows, then enforce.
4. Replace kube-proxy with Cilium and enable L2 announcements, to give the Forgejo registry a LAN load-balancer address (see [ADR 0003](0003-private-access-through-tailscale.md)).

Cilium itself is a Helm release with its values in `kubernetes/platform/cilium/values.yaml`, not an Argo CD Application. Argo CD's own pods need the CNI to run, so Argo CD cannot be the thing that installs or repairs it: if a bad sync broke Cilium, Argo CD would go down with it. Argo CD manages only Cilium's supporting resources in `kubernetes/platform/cilium/manifests/`, such as the L2 announcement policy and the IP pool.

## Rationale

- Network policies are enforced, so the ingress restrictions on n8n and Forgejo actually hold.
- Hubble shows each flow with its verdict. Audit mode records what a policy would drop without dropping it, so enforcement is switched on with evidence instead of hope.
- Cilium's L2 announcements give a LAN address to a `LoadBalancer` Service without a separate load-balancer controller. They require kube-proxy replacement, which is why that step was taken.

## Consequences

- The Flannel migration needed an outage. Backups were taken to USB first, stateful apps were stopped, and the old Flannel configuration was saved for rollback.
- Talos is configured with no CNI and no kube-proxy (`cluster.network.cni.name: none`, `cluster.proxy.disabled: true`). A freshly built cluster has no pod networking until Cilium is installed. Removing kube-proxy had to be done through the Talos config: deleting the DaemonSet alone would have it recreated.
- `default` enforcement isolates only the endpoints that a policy selects, in the directions it covers. The cluster is not default-deny; each exposed service needs its own policy.
- Cilium is changed with `helm upgrade` rather than by Argo CD, so its values file and the running release can drift. Cilium changes are planned, with the previous values saved for rollback, because a mistake breaks networking for the whole cluster.
