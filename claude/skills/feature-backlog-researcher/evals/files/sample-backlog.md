# Developer Portal Backlog

---

## 🔔 1. Alerting & Notifications

**BL-001 — Smart Alert Grouping**
The portal should group related alerts into a single incident rather than flooding the team with individual notifications. When multiple monitors fire within a short window on the same service or cluster, they should be correlated automatically, with a single incident card surfaced. This reduces alert fatigue and helps on-call engineers focus on the root cause rather than triaging dozens of duplicate pages.

**BL-002 — Alert Routing by Service Ownership**
Alerts should be routable to the correct team based on which service triggered them, using a service ownership registry. Engineers define ownership mappings (service → team → on-call schedule) and the portal automatically pages the right people. This eliminates the "who owns this?" delay at 3am and ensures runbooks and context are surfaced for the right audience.

**BL-003 — Escalation Policies**
The portal should support tiered escalation: if the primary on-call doesn't acknowledge within N minutes, escalate to a secondary or manager. Teams configure their own policies without needing a DevOps admin. This closes the gap between alerting tools and the actual response process, making SLA adherence measurable.

---

## 📊 2. Dashboards & Metrics

**BL-004 — Service Health Scorecard**
A per-service health view aggregating error rate, latency (p50/p95/p99), and uptime across a rolling window. The scorecard surfaces anomalies compared to baseline and shows week-over-week trends. Useful for engineering leads doing weekly reviews and for engineers debugging regressions before they become incidents.

**BL-005 — Deployment Impact Tracking**
After each deploy, the portal should automatically compare key metrics (error rate, latency) before and after the deployment window. This "deploy diff" view surfaces whether a release caused a regression or improvement, without requiring engineers to manually correlate timestamps. Integrates with CI/CD webhooks to capture deploy events.

---

*Sources: [PagerDuty](https://pagerduty.com) | [Datadog](https://datadoghq.com)*
