# 0004. Keep CI as plain workflows; no Dagger yet

- Status: Accepted
- Date: 2026-10-02

## Context

Dagger is used in my day-to-day work and is interesting for platform engineering and developer experience. The HomeLab already has many moving parts: Talos, Argo CD, Forgejo Actions, Cilium, Longhorn, Kyverno, Crossplane and the monitoring stack.

## Decision

Do not introduce Dagger pipelines into HomeLab CI yet. Keep using plain Forgejo Actions workflows, small scripts and pinned, checksum-verified tools until there is a concrete CI problem that Dagger solves.

## Rationale

CI should stay boring while boring works. Adding Dagger now would add an abstraction layer without a clear benefit. The priority is automation that is understandable, maintainable and easy to debug.

## Consequences

- CI stays simple, and each job can be read and reproduced locally with ordinary commands.
- Dagger can still be learned and evaluated in other contexts; HomeLab experiments with it stay small and non-critical.

## Revisit when

- CI logic is duplicated across several repositories.
- CI failures are hard to reproduce locally.
- YAML workflows become too complex to maintain.
- A shared pipeline module would clearly improve developer experience.
