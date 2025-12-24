# Aether

A policy-driven uplink arbitration framework for deterministic, auditable control-plane coordination in multi-provider networks.

**Version:** 1.0-Draft  
**Status:** Published Specification (RFC-style)  
**Target Environments:** Critical infrastructure, satellite–terrestrial hybrid networks, disaster response

-----

## Overview

Aether defines a constrained control-plane coordination layer for environments with multiple uplinks and heterogeneous providers (Satellite, Terrestrial, Cellular).

It does not replace routing protocols, forwarding behavior, or existing control systems. Instead, it defines how policy intent can be translated into auditable, deterministic directives without introducing inline dependencies or opaque decision logic.

The specification is intentionally limited in scope.

-----

## The Problem

Modern network control planes often suffer from scope creep. Orchestration systems frequently accumulate hidden responsibilities—Deep Packet Inspection (DPI), heuristic path computation, vendor-specific state—until they become opaque and unpredictable during failure.

Aether addresses this by constraining the control plane. It defines a strict interaction boundary between intent and execution that remains valid even when links flap, telemetry degrades, or controllers disappear.

**Core Thesis:** Aether deliberately trades capability for predictability.

-----

## The Aether Constraint

To preserve determinism and auditability, Aether explicitly refuses to perform the following functions:

- **No Payload Inspection:** Traffic classification must occur upstream; Aether operates on pre-tagged traffic classes.
- **No Path Computation:** Aether does not replace BGP, OSPF, IS-IS, or MPLS. It selects between existing, valid paths—not how paths are computed.
- **No Per-Flow State:** Arbitration is performed at the provider/uplink level, not at the session or user level.
- **No Inline Presence:** Aether provides out-of-band directives only. It never processes, forwards, proxies, buffers, or inspects data-plane packets.

**Aether does not compute paths, signal devices, or participate in convergence.**

These constraints are intentional. Relaxing them materially changes the failure and audit characteristics of the system.

-----

## How It Works

Aether functions as a **policy arbiter**, not a signaling protocol or path computation engine. It consumes two primary inputs to produce a single, deterministic output.

### Input/Output Model

**Inputs:**

- **Policy (Constraints):** Operator-defined rules (e.g., “Critical Telemetry: Path Stability > Latency”)
- **Telemetry (Observed State):** Link-level performance metrics (loss, latency, jitter) defined in `schema/telemetry-v1.json`

**Output:**

- **Directive:** A control-plane instruction for the underlying hardware or SDN controller

### Interaction Logic

```
[ Orchestrator ] → [ Policy ] → [ Aether Engine ]
                                       ↑
[ Link Telemetry ] ────────────────────┘
                                       ↓
                          [ Deterministic Directive ] → [ Hardware / BGP / SDN ]
```

**Fail-Safe:** If the Aether engine fails, the underlying hardware maintains its last-known valid state or reverts to local routing protocol defaults.

-----

## Skeptic’s Map

If you are approaching this from a networking background and thinking “this is just [X]”, the documents below address those boundaries directly.

|If you think…             |Read this…                    |To understand…                                                   |
|--------------------------|------------------------------|-----------------------------------------------------------------|
|“This is just SDN.”      
|`docs/01-architecture.md`     
|Why Aether is a governance constraint over SDN, not a replacement|
|“This can’t scale.”     
|`docs/00-non-goals.md`     
|How refusing flow state avoids scaling pressure    |
|“How would I deploy this?”
|`docs/03-integration-guide.md`
|The boundary between Aether and existing equipment       
|“Isn’t this just QoS?”   
|`docs/02-policy-schema.md` 
|How policy arbitration differs from packet prioritization  |

-----

## Repository Structure

### 1. Specification Documentation (`docs/`)

- **Non-Goals:** Explicit scope boundaries and what Aether will never do
- **Architecture:** Formal definition of the control-plane enforcement boundary
- **Policy Schema:** Deterministic grammar for expressing intent
- **Human Continuity Mode (HCM):** Bounded emergency state for disaster response
- **Conformance Specification:** Binary, testable requirements

### 2. Implementation Contracts (`schema/`)

Canonical JSON schemas defining the only interfaces Aether speaks:

- `telemetry-v1.json` — Standardized link-state reporting format
- `decision-log-v1.json` — Schema for tamper-evident audit logs
- `hcm-activation-v1.json` — Human Continuity Mode activation contract

### 3. Verification Scenarios (`examples/`)

Scenario walkthroughs demonstrating state transitions during:

- Flapping satellite uplinks
- Asymmetric telemetry loss
- Congested backhaul arbitration

These are explanatory, not benchmarks.

-----

## Intended Audience

- Satellite and hybrid connectivity operators
- Critical infrastructure network operators
- Humanitarian and disaster response coordination
- Procurement and oversight bodies seeking auditable, non-proprietary requirements

-----

## Status & Conformance

This repository contains the **v1.0-Draft specification** of Aether.

It is intentionally **specification-only:**

- No reference implementation
- No hosted service
- No vendor affiliation

The goal is to define enforceable boundaries for a control-plane coordination layer and invite critique from practitioners.

**Feedback is explicitly welcome on:**

- Failure-mode realism
- Boundary erosion in real deployments
- Whether these constraints are enforceable in practice

-----

## License

- **Code/Schemas:** Apache 2.0
- **Documentation:** CC BY 4.0
