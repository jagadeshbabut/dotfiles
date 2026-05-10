#!/usr/bin/env python3
"""
incident_audit.py — ICP Incident Ticket Auditor
================================================
Accepts a Jira issue JSON (from the ICP board) via stdin or --file and prints
a structured audit report against mandatory fields, process rules, SLA
requirements, and action item guidelines.

Usage:
    python3 incident_audit.py --file issue.json
    echo '<json>' | python3 incident_audit.py

The JSON must be the `fields` object (or the full MCP getJiraIssue response).

Known custom field IDs (slicepay.atlassian.net, ICP project — discovered 2026-03-17):
    customfield_12475  Incident start date time
    customfield_12476  Incident end date time
    customfield_12478  Incident detected date time
    customfield_12479  Incident detected by
    customfield_12481  Is it caused by a recent code/config change?
    customfield_12482  Is it caused by a recent infra change?
    customfield_12483  Is Internal RCA applicable?
    customfield_12484  Internal RCA doc Link
    customfield_12485  Customer impact
    customfield_12486  Volume (count) of impacted transactions
    customfield_12487  GTV of impacted transactions
    customfield_12488  Root cause module
    customfield_10413  Incident owner Team
    customfield_10364  Slack Link
"""

import json
import sys
import argparse
from datetime import date, datetime, timedelta

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

CLOUD_ID = "adeba97b-6326-4a84-8a07-efafb97be347"
ATLASSIAN_SITE = "slicepay.atlassian.net"

FIELDS = {
    "incident_start":       "customfield_12475",
    "incident_end":         "customfield_12476",
    "incident_detected":    "customfield_12478",
    "detected_by":          "customfield_12479",
    "code_change":          "customfield_12481",
    "infra_change":         "customfield_12482",
    "rca_applicable":       "customfield_12483",
    "rca_doc_link":         "customfield_12484",
    "customer_impact":      "customfield_12485",
    "volume_impacted":      "customfield_12486",
    "gtv_impacted":         "customfield_12487",
    "root_cause_module":    "customfield_12488",
    "owner_team":           "customfield_10413",
    "slack_link":           "customfield_10364",
}

VALID_DETECTED_BY   = {"system", "customer", "vendor"}
VALID_PRIORITIES    = {"p0", "p1", "p2"}
AUTO_TITLE_PATTERN  = "oncall incident alert created by"

# SLA: working days from incident end
RCA_SLA_DAYS = {"p0": 2, "p1": 5}

# Action item due date limits in working days from incident close
AI_DUE_DAYS = {"p0": 3, "p1": 12}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def working_days_between(start: date, end: date) -> int:
    """Count Mon–Fri days between two dates (exclusive of start, inclusive of end)."""
    days = 0
    current = start + timedelta(days=1)
    while current <= end:
        if current.weekday() < 5:
            days += 1
        current += timedelta(days=1)
    return days


def add_working_days(start: date, n: int) -> date:
    """Return the date n working days after start."""
    current = start
    added = 0
    while added < n:
        current += timedelta(days=1)
        if current.weekday() < 5:
            added += 1
    return current


def parse_jira_datetime(value) -> datetime | None:
    if not value:
        return None
    if isinstance(value, dict):
        value = value.get("value") or value.get("dateTime") or ""
    for fmt in ("%Y-%m-%dT%H:%M:%S.%f%z", "%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
        try:
            return datetime.strptime(str(value).strip(), fmt)
        except ValueError:
            pass
    return None


def extract_text(value) -> str:
    """Flatten ADF or plain string values to plain text."""
    if value is None:
        return ""
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, dict):
        if "name" in value:
            return str(value["name"])
        if "value" in value:
            return str(value["value"])
        if "content" in value:
            return _adf_to_text(value)
    if isinstance(value, list):
        return " ".join(extract_text(v) for v in value if v)
    return str(value)


def _adf_to_text(node) -> str:
    if isinstance(node, str):
        return node
    if isinstance(node, dict):
        text = node.get("text", "")
        children = node.get("content", [])
        return text + " ".join(_adf_to_text(c) for c in children)
    if isinstance(node, list):
        return " ".join(_adf_to_text(n) for n in node)
    return ""


def word_count(text: str) -> int:
    return len(text.split())


def get_field(fields: dict, key: str):
    cf_id = FIELDS.get(key)
    return fields.get(cf_id) if cf_id else None


# ---------------------------------------------------------------------------
# Audit engine
# ---------------------------------------------------------------------------

class AuditResult:
    PASS = "PASS"
    FAIL = "FAIL"
    WARN = "WARN"
    NA   = "N/A "

    def __init__(self):
        self.items: list[tuple[str, str, str]] = []  # (status, label, detail)

    def add(self, status: str, label: str, detail: str = ""):
        self.items.append((status, label, detail))

    @property
    def passed(self):  return sum(1 for s, _, _ in self.items if s == self.PASS)
    @property
    def failed(self):  return sum(1 for s, _, _ in self.items if s == self.FAIL)
    @property
    def warned(self):  return sum(1 for s, _, _ in self.items if s == self.WARN)
    @property
    def total(self):   return sum(1 for s, _, _ in self.items if s != self.NA)

    def sorted_items(self):
        order = {self.FAIL: 0, self.WARN: 1, self.PASS: 2, self.NA: 3}
        return sorted(self.items, key=lambda x: order.get(x[0], 9))


def audit_issue(issue: dict, today: date = None) -> str:
    today = today or date.today()
    fields = issue.get("fields", issue)
    key    = issue.get("key", "ICP-???")
    title  = extract_text(fields.get("summary", ""))
    status = extract_text((fields.get("status") or {}).get("name", ""))
    priority_raw = extract_text((fields.get("priority") or {}).get("name", "")).lower()
    issuelinks   = fields.get("issuelinks") or []

    # ------------------------------------------------------------------ #
    # SECTION 1 — Mandatory Fields
    # ------------------------------------------------------------------ #
    mf = AuditResult()

    # Issue start datetime
    start_val = get_field(fields, "incident_start")
    start_dt  = parse_jira_datetime(start_val)
    if start_val and start_dt:
        mf.add(mf.PASS, "Issue start datetime", str(start_dt.date()))
    elif start_val:
        mf.add(mf.PASS, "Issue start datetime", str(start_val))
    else:
        mf.add(mf.FAIL, "Issue start datetime", "MISSING")

    # Issue end datetime
    end_val = get_field(fields, "incident_end")
    end_dt  = parse_jira_datetime(end_val)
    if end_val and end_dt:
        mf.add(mf.PASS, "Issue end datetime", str(end_dt.date()))
    elif end_val:
        mf.add(mf.PASS, "Issue end datetime", str(end_val))
    else:
        mf.add(mf.FAIL, "Issue end datetime", "MISSING")

    # Issue detected datetime
    det_val = get_field(fields, "incident_detected")
    if det_val:
        mf.add(mf.PASS, "Issue detected datetime", extract_text(det_val))
    else:
        mf.add(mf.FAIL, "Issue detected datetime", "MISSING")

    # Issue detected by
    det_by = extract_text(get_field(fields, "detected_by")).lower()
    if det_by in VALID_DETECTED_BY:
        mf.add(mf.PASS, "Issue detected by", det_by)
    elif det_by:
        mf.add(mf.FAIL, "Issue detected by", f"INVALID value '{det_by}' — must be one of: system / customer / vendor")
    else:
        mf.add(mf.FAIL, "Issue detected by", "MISSING")

    # Incident Priority
    if priority_raw in VALID_PRIORITIES:
        mf.add(mf.PASS, "Incident Priority", priority_raw.upper())
    elif priority_raw:
        mf.add(mf.FAIL, "Incident Priority", f"INVALID value '{priority_raw}' — must be P0, P1, or P2")
    else:
        mf.add(mf.FAIL, "Incident Priority", "MISSING")

    # Code/config change
    code_chg = extract_text(get_field(fields, "code_change"))
    if code_chg:
        mf.add(mf.PASS, "Is it caused by a recent code/config change?", code_chg)
    else:
        mf.add(mf.FAIL, "Is it caused by a recent code/config change?", "MISSING")

    # Infra change
    infra_chg = extract_text(get_field(fields, "infra_change"))
    if infra_chg:
        mf.add(mf.PASS, "Is it caused by a recent infra change?", infra_chg)
    else:
        mf.add(mf.FAIL, "Is it caused by a recent infra change?", "MISSING")

    # Is Internal RCA applicable?
    rca_applicable_raw = extract_text(get_field(fields, "rca_applicable"))
    rca_applicable = rca_applicable_raw.lower() if rca_applicable_raw else ""
    if rca_applicable:
        mf.add(mf.PASS, "Is Internal RCA applicable?", rca_applicable_raw)
    else:
        mf.add(mf.FAIL, "Is Internal RCA applicable?", "MISSING")

    # Internal RCA doc link (conditional)
    rca_link = extract_text(get_field(fields, "rca_doc_link"))
    if rca_applicable == "no":
        mf.add(mf.NA, "Internal RCA doc link", "N/A (RCA not applicable)")
    elif rca_applicable == "yes":
        if rca_link:
            mf.add(mf.PASS, "Internal RCA doc link", rca_link[:80])
        else:
            mf.add(mf.FAIL, "Internal RCA doc link", "MISSING (RCA is applicable)")
    else:
        if rca_link:
            mf.add(mf.PASS, "Internal RCA doc link", rca_link[:80])
        else:
            mf.add(mf.FAIL, "Internal RCA doc link", "MISSING (cannot determine — 'Is Internal RCA applicable?' is unset)")

    # Customer impact
    impact = extract_text(get_field(fields, "customer_impact"))
    if not impact:
        mf.add(mf.FAIL, "Customer impact", "MISSING")
    elif word_count(impact) > 100:
        mf.add(mf.FAIL, "Customer impact", f"EXCEEDS 100 words ({word_count(impact)} words)")
    else:
        mf.add(mf.PASS, "Customer impact", f"({word_count(impact)} words) {impact[:60]}...")

    # Volume
    volume = extract_text(get_field(fields, "volume_impacted"))
    if volume:
        mf.add(mf.PASS, "Volume (count) of impacted transactions", volume)
    else:
        mf.add(mf.FAIL, "Volume (count) of impacted transactions", "MISSING")

    # GTV
    gtv = extract_text(get_field(fields, "gtv_impacted"))
    if gtv:
        mf.add(mf.PASS, "GTV of impacted transactions", gtv)
    else:
        mf.add(mf.FAIL, "GTV of impacted transactions", "MISSING")

    # Incident Owner Team
    owner_team = extract_text(get_field(fields, "owner_team"))
    if owner_team:
        mf.add(mf.PASS, "Incident Owner Team", owner_team)
    else:
        mf.add(mf.FAIL, "Incident Owner Team", "MISSING")

    # Root cause module
    root_module = extract_text(get_field(fields, "root_cause_module"))
    if root_module:
        mf.add(mf.PASS, "Root cause module", root_module)
    else:
        mf.add(mf.FAIL, "Root cause module", "MISSING")

    # ------------------------------------------------------------------ #
    # SECTION 2 — Process Compliance
    # ------------------------------------------------------------------ #
    pc = AuditResult()

    # Incident Owner Team set
    if owner_team:
        pc.add(pc.PASS, "Incident Owner Team set", owner_team)
    else:
        pc.add(pc.FAIL, "Incident Owner Team set", "MISSING — required by @incident-comm post-mitigation")

    # Is Internal RCA applicable? set
    if rca_applicable:
        pc.add(pc.PASS, "Is Internal RCA applicable? set", rca_applicable_raw)
    else:
        pc.add(pc.FAIL, "Is Internal RCA applicable? set", "MISSING — required by @incident-comm post-mitigation")

    # Descriptive title
    if title.lower().startswith(AUTO_TITLE_PATTERN):
        pc.add(pc.FAIL, "Incident title is descriptive",
               f"AUTO-GENERATED default title — replace with a descriptive summary: \"{title[:80]}\"")
    elif not title:
        pc.add(pc.FAIL, "Incident title is descriptive", "MISSING")
    else:
        pc.add(pc.PASS, "Incident title is descriptive", f"\"{title[:80]}\"")

    # Linked Incident Action Items
    action_items = [
        lnk for lnk in issuelinks
        if "Incident Action Item" in (
            extract_text(lnk.get("type", {}).get("name", "")) +
            extract_text((lnk.get("inwardIssue") or lnk.get("outwardIssue") or {}).get("issuetype", {}).get("name", ""))
        )
    ]
    if action_items:
        pc.add(pc.PASS, "Linked Incident Action Items", f"{len(action_items)} found")
    else:
        pc.add(pc.FAIL, "Linked Incident Action Items", "NONE FOUND")

    # Action Item fields (priority + due date)
    ai_section_items = []
    for lnk in action_items:
        linked = lnk.get("inwardIssue") or lnk.get("outwardIssue") or {}
        ai_key = linked.get("key", "?")
        ai_priority = extract_text((linked.get("fields", {}).get("priority") or {}).get("name", ""))
        ai_due = extract_text(linked.get("fields", {}).get("duedate", ""))
        ai_section_items.append((ai_key, ai_priority, ai_due))
        if not ai_priority:
            pc.add(pc.FAIL, f"Action Item {ai_key} — Priority", "MISSING")
        else:
            pc.add(pc.PASS, f"Action Item {ai_key} — Priority", ai_priority)
        if not ai_due:
            pc.add(pc.FAIL, f"Action Item {ai_key} — Due date", "MISSING")
        else:
            pc.add(pc.PASS, f"Action Item {ai_key} — Due date", ai_due)

    # Ticket status
    if status.lower() == "resolved" or status.lower() == "done":
        pc.add(pc.PASS, "Ticket status", "Resolved")
    else:
        pc.add(pc.WARN, "Ticket not yet Resolved", f"Current status: {status}")

    # ------------------------------------------------------------------ #
    # SECTION 3 — Action Item Priority Guidelines
    # ------------------------------------------------------------------ #
    ai_result = AuditResult()
    incident_close = end_dt.date() if end_dt else None

    for ai_key, ai_priority_str, ai_due_str in ai_section_items:
        ai_p = ai_priority_str.lower()
        ai_due_date = None
        if ai_due_str:
            try:
                ai_due_date = date.fromisoformat(ai_due_str)
            except ValueError:
                pass

        label = f"{ai_key} — Priority: {ai_priority_str or 'UNSET'}, Due: {ai_due_str or 'MISSING'}"

        if not ai_priority_str:
            ai_result.add(ai_result.FAIL, label, "Priority not set")
            continue
        if not ai_due_date:
            ai_result.add(ai_result.FAIL, label, "Due date not set")
            continue

        if incident_close and ai_p in AI_DUE_DAYS:
            limit = add_working_days(incident_close, AI_DUE_DAYS[ai_p])
            if ai_due_date > limit:
                ai_result.add(ai_result.FAIL, label,
                    f"Due date {ai_due_date} exceeds {AI_DUE_DAYS[ai_p]}-working-day limit "
                    f"({limit}) for {ai_p.upper()} action item")
            else:
                ai_result.add(ai_result.PASS, label, f"Due within {ai_p.upper()} limit ({limit})")
        else:
            ai_result.add(ai_result.PASS, label)

    # ------------------------------------------------------------------ #
    # SECTION 4 — RCA SLA
    # ------------------------------------------------------------------ #
    rca_sla_lines = []
    if rca_applicable == "no":
        rca_sla_lines.append("RCA SLA: N/A (RCA not applicable)")
        rca_sla_status = "N/A"
    else:
        sla_days = RCA_SLA_DAYS.get(priority_raw, None)
        if not sla_days:
            rca_sla_lines.append(f"RCA SLA: Cannot determine — unrecognised priority '{priority_raw}'")
            rca_sla_status = "UNKNOWN"
        elif not end_dt:
            rca_sla_lines.append("RCA SLA: Incident end datetime is MISSING — cannot calculate exact deadline.")
            rca_sla_lines.append(f"         Ticket was created on {issue.get('fields', {}).get('created', 'unknown date')[:10]}.")
            rca_sla_lines.append(f"         Given ticket age, RCA SLA is almost certainly BREACHED.")
            rca_sla_status = "SLA BREACHED (end datetime missing)"
        else:
            deadline = add_working_days(end_dt.date(), sla_days)
            rca_sla_lines.append(f"Priority   : {priority_raw.upper()}")
            rca_sla_lines.append(f"RCA SLA    : {sla_days} working days from incident end ({end_dt.date()})")
            rca_sla_lines.append(f"Deadline   : {deadline}")
            if rca_link:
                rca_sla_lines.append(f"RCA link   : {rca_link[:80]}")
                rca_sla_status = "COMPLIANT"
            elif today > deadline:
                rca_sla_lines.append(f"RCA link   : MISSING")
                rca_sla_status = "SLA BREACHED"
            else:
                rca_sla_lines.append(f"RCA link   : MISSING")
                rca_sla_status = "AT RISK"

    # ------------------------------------------------------------------ #
    # SECTION 5 — RCA Presenter Rule
    # ------------------------------------------------------------------ #
    rca_presenter_lines = []
    if rca_link:
        rca_presenter_lines.append(
            "[WARN] Verify RCA Presenter: RCAs must be presented by Sr ICs or EMs from the "
            "owner team — not by on-call devs. Confirm the presenter before scheduling."
        )

    # ------------------------------------------------------------------ #
    # Render report
    # ------------------------------------------------------------------ #
    lines = []
    W = 48

    def hr(): return "=" * W
    def sh(): return "-" * W

    lines += [hr(), f"Incident Audit Report: {key}", f"Audited on : {today}", hr(), ""]

    lines += ["MANDATORY FIELDS", sh()]
    for status_s, label, detail in mf.sorted_items():
        suffix = f": {detail}" if detail else ""
        lines.append(f"[{status_s}] {label}{suffix}")
    lines.append("")

    lines += ["PROCESS COMPLIANCE", sh()]
    for status_s, label, detail in pc.sorted_items():
        suffix = f": {detail}" if detail else ""
        lines.append(f"[{status_s}] {label}{suffix}")
    lines.append("")

    lines += ["SLA ADHERENCE", sh()]
    lines += rca_sla_lines
    lines.append(f"\nStatus: {rca_sla_status}")
    lines.append("")

    if rca_presenter_lines:
        lines += ["RCA PRESENTER", sh()] + rca_presenter_lines + [""]

    lines += ["ACTION ITEMS", sh()]
    if ai_result.items:
        for status_s, label, detail in ai_result.sorted_items():
            suffix = f" — {detail}" if detail else ""
            lines.append(f"[{status_s}] {label}{suffix}")
    else:
        lines.append("No linked Incident Action Items found.")
    lines.append("")

    total = mf.total + pc.total + ai_result.total
    passed = mf.passed + pc.passed + ai_result.passed
    failed = mf.failed + pc.failed + ai_result.failed
    warned = mf.warned + pc.warned + ai_result.warned

    lines += ["SUMMARY", sh()]
    lines += [
        f"Total checks : {total}",
        f"Passed       : {passed}",
        f"Failed       : {failed}",
        f"Warnings     : {warned}",
        f"RCA SLA      : {rca_sla_status}",
        "",
    ]

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Audit an ICP Jira incident ticket JSON")
    parser.add_argument("--file", "-f", help="Path to JSON file (defaults to stdin)")
    parser.add_argument("--today", help="Override today's date (YYYY-MM-DD) for SLA testing")
    args = parser.parse_args()

    today = date.fromisoformat(args.today) if args.today else date.today()

    if args.file:
        with open(args.file) as fh:
            raw = json.load(fh)
    else:
        raw = json.load(sys.stdin)

    # Accept both the full MCP response envelope and a bare issue dict
    if "issues" in raw:
        issues = raw["issues"].get("nodes", [])
    elif "key" in raw:
        issues = [raw]
    else:
        issues = [raw]

    reports = [audit_issue(issue, today=today) for issue in issues]
    print("\n\n".join(reports))

    if len(issues) > 1:
        print("=" * 48)
        print(f"ROLL-UP: {len(issues)} tickets audited")
        print("=" * 48)


if __name__ == "__main__":
    main()
