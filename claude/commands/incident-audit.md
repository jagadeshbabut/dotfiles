# Command: /incident-audit

Audits an ICP JIRA incident ticket against the new mandatory incident management
fields, process rules, SLA requirements, and action item guidelines.

---

## Input

A JIRA ticket ID from the ICP board (e.g. `ICP-1234`), or a comma-separated list.

Examples:
> /incident-audit ICP-1234
> /incident-audit ICP-1234, ICP-1235

---

## Audit Script

The audit logic lives in a stored Python script. **Do not re-derive or re-implement it.**

```
~/.claude/scripts/incident_audit.py
```

The script contains:
- All known ICP custom field IDs (discovered 2026-03-17)
- Mandatory field assertions
- Process compliance checks
- RCA SLA calculations
- Action item priority validation
- Formatted report output

---

## Known Custom Field IDs (slicepay.atlassian.net — ICP project)

> Cloud ID: `adeba97b-6326-4a84-8a07-efafb97be347`
> Pass these explicitly in the `fields` array to `getJiraIssue`.

| Custom Field ID       | Field Name                                      |
|-----------------------|-------------------------------------------------|
| `customfield_12475`   | Incident start date time                        |
| `customfield_12476`   | Incident end date time                          |
| `customfield_12478`   | Incident detected date time                     |
| `customfield_12479`   | Incident detected by                            |
| `customfield_12481`   | Is it caused by a recent code/config change?    |
| `customfield_12482`   | Is it caused by a recent infra change?          |
| `customfield_12483`   | Is Internal RCA applicable?                     |
| `customfield_12484`   | Internal RCA doc Link                           |
| `customfield_12485`   | Customer impact                                 |
| `customfield_12486`   | Volume (count) of impacted transactions         |
| `customfield_12487`   | GTV of impacted transactions                    |
| `customfield_12488`   | Root cause module                               |
| `customfield_10413`   | Incident owner Team                             |
| `customfield_10364`   | Slack Link                                      |

Standard fields to always include: `summary`, `status`, `priority`, `issuelinks`.

---

## Execution Steps

### Step 1 — Fetch the JIRA ticket(s)

Use `mcp__claude_ai_Atlassian__getJiraIssue` for each ticket ID with:
- `cloudId`: `adeba97b-6326-4a84-8a07-efafb97be347`
- `fields`: all custom field IDs from the table above plus `summary`, `status`, `priority`, `issuelinks`
- `responseContentFormat`: `markdown`

### Step 2 — Save response and run the audit script

Save the raw JSON response to a temp file, then run:

```bash
echo '<json_response>' | python3 ~/.claude/scripts/incident_audit.py
```

Or with a file:
```bash
python3 ~/.claude/scripts/incident_audit.py --file /tmp/icp_issue.json
```

The script outputs the full structured audit report. Print it as-is.

### Step 3 — Supplement with linked Action Item details (if any)

If `issuelinks` in the response contains linked issues, fetch each linked Action Item ticket
using `getJiraIssue` (fields: `summary`, `priority`, `duedate`, `status`, `sprint`) and
re-run or manually verify the ACTION ITEMS section of the report.

---

## Rules

- Working days = Monday–Friday, excluding weekends (do not count public holidays unless data is available)
- Never modify the JIRA ticket during this audit — this is read-only
- If the Atlassian MCP is unavailable, tell the user to provide ticket details manually and
  run the script against the pasted JSON
- If `Is Internal RCA applicable?` is `No`, RCA checks are automatically marked N/A by the script
- Always surface FAIL items first in the report, then WARN, then PASS (script handles ordering)
