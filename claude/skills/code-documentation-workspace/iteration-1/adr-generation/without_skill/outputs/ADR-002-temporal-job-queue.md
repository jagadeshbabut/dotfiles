# ADR-002: Replace BullMQ with Temporal for Background Job Queue

**Status:** Accepted
**Date:** 2026-05-15
**Deciders:** Engineering Team
**Technical Story:** Migration from BullMQ (Redis-backed) to Temporal (durable workflow engine)

---

## Context

Our system processes background jobs using **BullMQ**, a Node.js job queue backed by Redis. Over time, two critical operational problems have emerged:

1. **Job loss during Redis failovers.** When Redis undergoes a primary-replica failover (whether planned or unplanned), in-flight jobs and queued jobs that have not yet been acknowledged are dropped silently. BullMQ relies on Redis's in-memory state; it has no durable persistence layer. During a failover window — typically 5–30 seconds — any jobs dequeued by workers but not yet committed to a persistent store are lost. Retrying lost jobs requires either external reconciliation logic or manual intervention.

2. **Inability to support long-running, resumable workflows.** Several product features require workflows that span minutes to hours — for example, multi-step data processing pipelines, human-in-the-loop approval flows, and scheduled batch operations. BullMQ jobs are designed for short-lived, fire-and-forget tasks. Implementing pause/resume semantics on top of BullMQ requires significant custom infrastructure (persistent state tracking, external scheduling, manual checkpointing) that is brittle and hard to reason about.

These limitations have caused production incidents and are blocking feature development that requires reliable, long-duration workflow orchestration.

---

## Decision

We will migrate our background job queue from **BullMQ** to **Temporal**.

Temporal is an open-source durable workflow engine. It stores workflow state — including every event, input, output, and timer — in a persistent event log. Workers execute workflow and activity code, but all state lives in the Temporal server (backed by either Cassandra or PostgreSQL). If a worker crashes mid-execution, Temporal replays the event history to restore exact execution state when the worker comes back online. No jobs are lost.

### What we are adopting

- **Temporal Server** (self-hosted or Temporal Cloud) as the workflow orchestration backend
- **Temporal SDK** (TypeScript/Node.js) to define workflows and activities
- A dedicated **Temporal Worker process** deployed alongside existing application services
- Temporal's built-in **retry policies**, **timers**, **signals**, and **queries** to replace custom BullMQ job management logic

### What we are replacing

- BullMQ job producers and consumers
- Redis-backed queue state
- Custom retry and scheduling logic built on top of BullMQ

---

## Consequences

### Positive

- **Durability by default.** Temporal persists every workflow event to its datastore. Jobs survive Redis failovers, worker crashes, and network partitions without data loss.
- **Native long-running workflow support.** Workflows can run for seconds, hours, or days. They can pause on timers, wait for external signals (e.g., human approval), and resume seamlessly — without any custom checkpointing code.
- **Deterministic replay.** Temporal's SDK enforces determinism constraints that make workflows reproducible and debuggable. The event history is a full audit log of every execution.
- **Richer primitives.** Signals (send data into a running workflow), queries (inspect live workflow state), and child workflows compose naturally, replacing ad-hoc patterns built on top of BullMQ pub/sub.
- **Visibility and observability.** Temporal's Web UI provides real-time workflow status, event history, pending activities, and failure details out of the box — significantly better than BullMQ's dashboard.
- **Separation of concerns.** Business logic (defined in workflow and activity code) is fully decoupled from execution infrastructure. Temporal handles retries, timeouts, and state; application code handles domain logic.

### Negative / Trade-offs

- **Additional operational component.** Temporal requires running and maintaining a Temporal Server (or paying for Temporal Cloud). This includes a persistent datastore (PostgreSQL recommended for our scale), and optionally Elasticsearch for advanced visibility. This increases infrastructure complexity and ops overhead.
- **Dedicated worker process required.** Unlike BullMQ, where the same Node.js process can both serve HTTP requests and process jobs, Temporal workers are typically run as separate processes. This adds a deployment artifact and requires updates to CI/CD pipelines, health checks, and monitoring.
- **Learning curve.** Temporal's programming model — deterministic workflows, activity isolation, event sourcing — is conceptually different from BullMQ's simpler queue-and-consumer model. Developers need to understand determinism constraints (no direct I/O in workflows, no `Date.now()` or `Math.random()`, etc.) to write correct code.
- **SDK verbosity.** Temporal workflows require more boilerplate than BullMQ job handlers. Simple fire-and-forget tasks that previously required ~10 lines will require ~40–60 lines (workflow definition, activity definition, worker registration).
- **Migration cost.** Existing BullMQ producers and consumers must be migrated. During transition, we will run both systems in parallel, which adds temporary complexity.

---

## Alternatives Considered

### 1. Keep BullMQ and add a Redis persistence layer

**Approach:** Move to Redis with AOF (Append-Only File) persistence and replication, and/or run Redis with a more robust failover strategy (e.g., Redis Sentinel with tighter timeouts, or Redis Cluster).

**Rejected because:** This addresses the durability concern partially but does not solve the fundamental limitation: BullMQ's job state is not transactionally consistent with application state. AOF + replication reduces the loss window but does not eliminate it. More importantly, this approach does not address the need for long-running, resumable workflows — BullMQ has no native support for pausing and resuming mid-workflow. We would still need to build custom orchestration on top.

### 2. Migrate to a database-backed queue (e.g., pg-boss or River)

**Approach:** Use a PostgreSQL-backed job queue such as `pg-boss` (Node.js) or `River` (Go). These use the application's existing Postgres database as the queue store, giving ACID-backed durability without a separate infrastructure component.

**Rejected because:** While this solves the durability problem and avoids a new infrastructure dependency, it does not provide workflow orchestration primitives. Long-running workflows (pause/resume, signals, timers, child workflows) would still require custom implementation. For our current roadmap, the workflow orchestration capability is a first-class requirement, not an optional feature.

### 3. AWS Step Functions or Google Cloud Workflows

**Approach:** Use a managed cloud-native workflow orchestration service.

**Rejected because:** These services create tight coupling to a specific cloud provider and require workflow definitions in JSON/YAML DSLs (e.g., Amazon States Language) rather than code. Temporal's code-first model is significantly easier to test, version, and reason about. Additionally, vendor lock-in conflicts with our multi-cloud flexibility goals.

---

## Migration Plan (High Level)

1. **Infrastructure:** Provision Temporal Server with PostgreSQL backend (or evaluate Temporal Cloud for managed option).
2. **Worker service:** Create a dedicated Temporal worker process; add to Docker Compose and Kubernetes deployments.
3. **Parallel operation:** During migration, BullMQ and Temporal run concurrently. New workflows are written in Temporal; existing BullMQ jobs are migrated progressively.
4. **Feature migration:** Port each BullMQ queue to a Temporal workflow, starting with the highest-impact (most error-prone) queues.
5. **Decommission:** Once all workflows are migrated and verified in production, remove BullMQ and Redis queue infrastructure.

---

## References

- [Temporal Documentation](https://docs.temporal.io)
- [Temporal TypeScript SDK](https://typescript.temporal.io)
- [BullMQ Documentation](https://docs.bullmq.io)
- [Temporal vs BullMQ comparison](https://temporal.io/blog/temporal-vs-bull)
- Internal post-mortem: Redis failover incident (reference: INC-0047)
