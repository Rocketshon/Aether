# Aether

![Tests](https://github.com/Obelus-Labs-LLC/Aether/actions/workflows/test.yml/badge.svg)
![TLA+](https://github.com/Obelus-Labs-LLC/Aether/actions/workflows/tla.yml/badge.svg)
![Conformance](https://github.com/Obelus-Labs-LLC/Aether/actions/workflows/api-conformance.yml/badge.svg)

A policy-driven uplink arbitration framework for deterministic, auditable control-plane coordination in multi-provider networks.

**Version:** 1.0-Draft
**Status:** Specification + Reference Implementation (52 tests)
**Target Environments:** Critical infrastructure, satellite-terrestrial hybrid networks, disaster response

-----

## Overview

Aether defines a constrained control-plane coordination layer for environments with multiple uplinks and heterogeneous providers (Satellite, Terrestrial, Cellular).

It does not replace routing protocols, forwarding behavior, or existing control systems. Instead, it defines how policy intent can be translated into auditable, deterministic directives without introducing inline dependencies or opaque decision logic.

The specification is intentionally limited in scope.

-----

## The Problem

Modern network control planes often suffer from scope creep. Orchestration systems frequently accumulate hidden responsibilities — Deep Packet Inspection (DPI), heuristic path computation, vendor-specific state — until they become opaque and unpredictable during failure.

Aether addresses this by constraining the control plane. It defines a strict interaction boundary between intent and execution that remains valid even when links flap, telemetry degrades, or controllers disappear.

**Core Thesis:** Aether deliberately trades capability for predictability.

-----

## The Aether Constraint

To preserve determinism and auditability, Aether explicitly refuses to perform the following functions:

- **No Payload Inspection:** Traffic classification must occur upstream; Aether operates on pre-tagged traffic classes.
- **No Path Computation:** Aether does not replace BGP, OSPF, IS-IS, or MPLS. It selects between existing, valid paths — not how paths are computed.
- **No Per-Flow State:** Arbitration is performed at the provider/uplink level, not at the session or user level.
- **No Inline Presence:** Aether provides out-of-band directives only. It never processes, forwards, proxies, buffers, or inspects data-plane packets.

-----

## How It Works

Aether functions as a **policy arbiter**, not a signaling protocol or path computation engine.

**Inputs:**

- **Policy (Constraints):** Operator-defined rules (e.g., "Critical Telemetry: Path Stability > Latency")
- **Telemetry (Observed State):** Link-level performance metrics (loss, latency, jitter) defined in `schema/telemetry-v1.json`

**Output:**

- **Directive:** A control-plane instruction for the underlying hardware or SDN controller

**Fail-Safe:** If the Aether engine fails, the underlying hardware maintains its last-known valid state or reverts to local routing protocol defaults.

-----

## Repository Structure

### Specification (`docs/`)

| Document | Description |
|----------|-------------|
| `docs/00-non-goals.md` | Explicit scope boundaries and what Aether will never do |
| `docs/01-architecture.md` | Control-plane enforcement boundary and decision flow |
| `docs/02-policy-schema.md` | Deterministic grammar for expressing policy intent |
| `docs/03-integration-guide.md` | Adapter model and equipment integration requirements |
| `docs/04-human-continuity-mode.md` | Time-bounded emergency operating mode for disaster response |
| `docs/glossary.md` | Term definitions |
| `conformance.md` | Binary conformance model: 10 core requirements, 8 forbidden behaviors |

### Research

| Document | Description |
|----------|-------------|
| `AETHER_FRAMEWORK_RESEARCH.md` | Background research, design rationale, and open questions |

### Schemas (`schema/`)

| Schema | Description |
|--------|-------------|
| `schema/telemetry-v1.json` | Link-state reporting format |
| `schema/decision-log-v1.json` | Tamper-evident audit log schema |
| `schema/hcm-activation-v1.json` | Human Continuity Mode activation contract |

### Reference Implementation (`aether-ref/`)

Rust reference implementation with HTTP API server. See [`aether-ref/README.md`](aether-ref/README.md) for build, usage, and deployment instructions.

| Component | Path | Description |
|-----------|------|-------------|
| Policy engine | `src/engine/` | Deterministic evaluation with conflict resolution |
| HTTP API | `src/api/http.rs`, `openapi.yaml` | Axum server, 10 endpoints, OpenAPI 3.1 |
| Authorization | `src/authz/` | Cedar-based API authorization (optional, Rust-native) |
| Netlink adapter | `src/adapter/netlink.rs` | Linux `ip route` with idempotent apply and rollback |
| Telemetry trust | `src/adapter/registry.rs` | HMAC verification, sequence monotonicity, heartbeat liveness |
| Audit logging | `src/audit/` | HMAC-SHA256 tamper-evident decision chain |
| HCM | `src/hcm/` | Human Continuity Mode lifecycle management |
| Formal model | `formal/AetherSpec.tla` | TLA+ — 5 invariants, CI-verified on every push |
| Deployment | `deploy/` | Docker Compose with Grafana + Loki observability stack |
| Failure modes | `docs/failure-modes.md` | Explicit outputs for degraded/missing/expired scenarios |
| Examples | `examples/policies/` | Critical infrastructure, disaster response, multi-provider |

### Testing & Conformance

| Path | Description |
|------|-------------|
| `tests/conformance/*.hurl` | 7 Hurl test files covering AETH-C conformance requirements |
| `tests/conformance/setup.sh` | Server bootstrap script for conformance testing |
| `tests/topology/` | Containerlab multi-link integration test topology |
| `.github/workflows/test.yml` | Rust test + clippy + fmt on push/PR |
| `.github/workflows/tla.yml` | TLC model checker on formal spec changes |
| `.github/workflows/api-conformance.yml` | Schemathesis API fuzzing against OpenAPI spec |

-----

## Testing

### Unit Tests (52 tests)
```bash
cd aether-ref && cargo test
```

### API Conformance (Hurl)
```bash
cd aether-ref
bash ../tests/conformance/setup.sh
hurl --test ../tests/conformance/*.hurl
```

Tests cover:
- Health endpoint (AETH-C-007)
- Policy loading and retrieval (AETH-C-008)
- Deterministic evaluation (AETH-C-003)
- Audit log completeness (AETH-C-007)
- HCM lifecycle (Level 2)
- HCM mutual exclusion (AETH-F-008)
- Routing non-participation (AETH-C-010)

### API Fuzzing (Schemathesis)
```bash
pip install schemathesis
st run aether-ref/openapi.yaml --base-url http://localhost:8080 --checks all
```

Property-based testing that auto-generates edge cases and invalid inputs from the OpenAPI spec.

### Formal Verification (TLA+)
The TLA+ model at `formal/AetherSpec.tla` is verified in CI via TLC model checker on every push to `formal/`. Five invariants are checked:
- **PolicyCompleteness** — Every evaluation produces a decision
- **ConflictDeterminism** — Same state always produces the same decision
- **HcmMutualExclusion** — No concurrent HCM activations
- **HcmBoundedDuration** — Active HCM never exceeds max duration
- **HcmCumulativeBound** — Cumulative HCM duration is bounded

-----

## Cedar Authorization

Optional API authorization via [Cedar](https://www.cedarpolicy.com/) (Apache 2.0, Rust-native crate — no sidecar, no network calls). Enable with:

```bash
aether serve --bind 0.0.0.0:8080 --authz-policy deploy/authz-policy.cedar
```

The sample policy (`deploy/authz-policy.cedar`):
- Grants `admin` full access to all operations
- Allows all authenticated users to evaluate, query audit, read policies, ingest telemetry
- Restricts `readonly` users from loading policies or managing HCM

Authorization maps HTTP routes to Cedar actions (e.g., `POST /policies` → `Action::"LoadPolicy"`) and checks the `X-Aether-Principal` header.

-----

## Observability (Grafana + Loki)

```bash
cd aether-ref/deploy && docker compose up
```

Starts the Aether engine alongside a pre-configured observability stack:

- **Grafana** at `localhost:3000` — Aether Decisions dashboard with 4 panels:
  - Decision timeline (log stream)
  - Audit chain status (stat panel)
  - Policy hit distribution (bar chart)
  - HCM activation events (log stream)
- **Loki** — Log aggregation for structured decision JSON
- **Promtail** — Automatic log shipping from the Aether container

-----

## Network Integration Testing (Containerlab)

```bash
cd tests/topology
sudo containerlab deploy -t aether-multilink.clab.yml
```

Deploys a 5-node topology simulating a multi-provider environment:

| Node | Role | Network Impairment |
|------|------|--------------------|
| `aether-controller` | Aether engine | None |
| `satellite-gw` | LEO provider gateway | 40ms delay, 10ms jitter, 2% loss |
| `cellular-gw` | LTE provider gateway | 15ms delay, 5ms jitter |
| `terrestrial-gw` | Fiber provider gateway | None |
| `client` | Test client | Connected to all gateways |

See `tests/topology/README.md` for setup, failover testing, and teardown instructions.

-----

## CI Integration

| Workflow | Trigger | What It Does |
|----------|---------|-------------|
| `test.yml` | Push/PR | `cargo fmt --check` + `cargo clippy` + `cargo test` |
| `tla.yml` | Push to `formal/` | TLC model checker verifies all 5 invariants |
| `api-conformance.yml` | Push/PR | Build, start server, Schemathesis fuzz all endpoints |

-----

## Intended Audience

- Satellite and hybrid connectivity operators
- Critical infrastructure network operators
- Humanitarian and disaster response coordination
- Procurement and oversight bodies seeking auditable, non-proprietary requirements

-----

## License

- **Code/Schemas:** Apache 2.0
- **Documentation:** CC BY 4.0

---

If this specification was useful to you, consider giving it a star — it helps others discover it.
