# ADR-002: Replace BullMQ with Temporal for Background Job Queue

## Status
Accepted

## Context

Our background job processing was built on BullMQ, a Redis-backed queue library for Node.js.
During production operations we observed two critical failure modes:

1. **Job loss during Redis failovers.** When Redis undergoes a failover (primary failure, Sentinel
   promotion, or cluster rebalancing), in-flight jobs are lost. BullMQ relies on Redis atomicity
   for job state, but does not provide durable persistence across failover events. We experienced
   data loss incidents where payment processing and notification jobs silently dropped.

2. **No support for long-running, pauseable workflows.** Several business processes (order
   fulfillment, async onboarding sequences, multi-step approval pipelines) require workflows that
   span minutes to days, may need to pause for external events, and must be resumable after
   infrastructure restarts. BullMQ jobs are ephemeral — a worker restart abandons any in-progress
   job.

Options considered:

- **Keep BullMQ + Redis Sentinel tuning**: Reduces failover window but does not eliminate job loss.
  Does not address long-running workflow needs.
- **BullMQ + persistent Redis (AOF/RDB)**: Improves durability but adds Redis operational
  complexity and still has a durability gap at the application layer.
- **AWS SQS + Step Functions**: Cloud-native and durable, but vendor lock-in and significant
  rewrite cost. Step Functions has per-state-transition pricing that becomes expensive at scale.
- **Temporal**: Durable workflow engine with an SDK-first programming model. Workflows are
  replayed from an event history, making them resilient to worker and infrastructure failures.
  Requires a separate Temporal server (self-hosted or Temporal Cloud) and a dedicated worker
  process.

## Decision

Replace BullMQ with Temporal as the background job and workflow engine. Workflows and activities
will be written using the Temporal TypeScript SDK. The Temporal server will be self-hosted on
Kubernetes initially, with a migration path to Temporal Cloud if operational overhead proves
unacceptable.

## Rationale

- **Durability is the primary requirement.** Temporal persists every workflow state transition to
  its own database (backed by PostgreSQL or Cassandra). Job loss during Redis failover is
  structurally eliminated — there is no Redis in the critical path for durability.
- **Long-running workflows are first-class.** Temporal workflows can sleep for days, wait on
  signals from external systems, and resume after worker restarts. This directly unblocks the
  order fulfillment and approval pipeline features that BullMQ could not support.
- **Replay-based execution model catches regression bugs.** Because Temporal replays workflow
  history on recovery, non-determinism bugs surface during testing rather than silently corrupting
  state in production.
- **BullMQ rejected** because it cannot guarantee durability across Redis failovers — this was the
  root cause of our production incidents, not a configuration issue.
- **SQS + Step Functions rejected** because the programming model requires externalising all state
  to S3/DynamoDB, the per-transition cost model is unpredictable, and it would tightly couple the
  application to AWS.

## Consequences

**What becomes easier:**
- Long-running, multi-step workflows can be written as ordinary TypeScript functions with `await` —
  no state machine DSL required.
- Failed workflows can be retried or cancelled from the Temporal Web UI without code changes.
- Workflow history provides a built-in audit trail for compliance-sensitive processes.
- Dead-letter handling is replaced by Temporal's retry policies and workflow failure states.

**What becomes harder or more expensive:**
- A Temporal server (or Temporal Cloud subscription) must be operated. This adds infrastructure
  surface, monitoring requirements, and on-call scope.
- Workers must be deployed as a separate process alongside API servers. Deployment pipelines need
  to account for worker versioning and the Temporal versioning API (`workflow.patched`) for
  safe in-flight workflow migrations.
- The Temporal programming model has a learning curve: activities vs. workflows, determinism
  constraints, and signal/query patterns are not intuitive for engineers coming from a simple
  queue model.
- Local development requires running a Temporal server (via `temporal server start-dev` CLI or
  Docker Compose), adding friction to onboarding.

**New decisions this creates:**
- Choice of Temporal persistence backend: PostgreSQL (reuses existing infra) vs. Cassandra
  (better at scale but new operational burden). Default to PostgreSQL.
- Decision on Temporal Cloud vs. self-hosted: revisit after 6 months of self-hosted operation.
- Worker versioning and deployment strategy for safely migrating in-flight workflows.
- Observability strategy: Temporal metrics (Prometheus), workflow search attributes, and alerting
  on workflow failure rates.

## AI Context

This ADR records a load-bearing infrastructure decision driven by a **production data loss
incident**, not a theoretical preference. The switch to Temporal is non-negotiable unless the
core problem (durable job persistence across infrastructure failures) is solved by another means.

Key invariants an AI agent must not assume are changeable:
- Do not suggest reverting to BullMQ or any Redis-backed queue for jobs that require durability.
  Redis-backed queues have an acknowledged gap during failover that caused real data loss.
- The Temporal worker process is intentional and must remain separate from the API server process.
  Mixing them would couple workflow scaling to HTTP request scaling, which breaks Temporal's
  execution model.
- Workflow code must remain deterministic. Do not introduce `Math.random()`, `Date.now()`, or
  non-deterministic SDK calls directly inside workflow functions — use `workflow.now()` and
  seed randomness through activities instead.
- The PostgreSQL backend for Temporal reuses existing database infrastructure. Do not propose
  Cassandra without a capacity justification — it adds a new stateful system to operate.

What would invalidate this decision: if Temporal's operational overhead (incident response,
upgrades, worker versioning complexity) consistently exceeds the cost of the data loss incidents
it prevents, the team should re-evaluate Temporal Cloud or a managed alternative.
