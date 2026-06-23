#!/usr/bin/env python3
"""
Fireflies meeting summary generator.

Usage:
  fireflies-summary.py                        # last 60 days
  fireflies-summary.py --start 2026-05-01     # from date to today
  fireflies-summary.py --start 2026-05-01 --end 2026-06-01
  fireflies-summary.py --days 30              # last N days
  fireflies-summary.py --mode notes           # meeting notes only
  fireflies-summary.py --mode actions         # action items only (default: both)
  fireflies-summary.py --mine                 # only show your action items
"""

import argparse
import datetime
import json
import os
import re
import sys
import urllib.request
import urllib.error

API_URL = "https://api.fireflies.ai/graphql"
KEY_FILE = os.path.expanduser("~/.config/fireflies/api_key")
MY_NAME_VARIANTS = ["jagadesh thangavelu", "jagadesh", "jaga"]

ETA_PATTERNS = [
    r"\bby end of(?: the)? day\b",
    r"\bby (?:tomorrow|today|tonight)\b",
    r"\bwithin (?:a |the )?(?:day|week|hour|two days?|24 hours?|48 hours?)\b",
    r"\bby (?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b",
    r"\bend of (?:the )?week\b",
    r"\bwithin \d+ (?:days?|hours?|weeks?)\b",
    r"\bby next week\b",
    r"\basap\b",
    r"\bimmediately\b",
    r"\btoday\b",
    r"\btomorrow\b",
    r"\bthis week\b",
    r"\bthis sprint\b",
    r"\bearly \w+\b",
    r"\bend of \w+\b",
]


# ── API ────────────────────────────────────────────────────────────────────────

def load_api_key():
    if not os.path.exists(KEY_FILE):
        sys.exit(f"API key not found at {KEY_FILE}\n"
                 "Run: mkdir -p ~/.config/fireflies && echo YOUR_KEY > ~/.config/fireflies/api_key")
    return open(KEY_FILE).read().strip()


def graphql(query, api_key):
    body = json.dumps({"query": query}).encode()
    req = urllib.request.Request(
        API_URL,
        data=body,
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code}: {e.read().decode()}")


def fetch_transcripts(api_key, start_ms, end_ms):
    """Fetch all transcripts in the date range using skip-based pagination."""
    all_transcripts = []
    skip = 0
    limit = 50

    while True:
        q = (
            f"{{ transcripts(limit: {limit}, skip: {skip}) "
            "{ id title date duration participants "
            "summary { action_items overview } } }"
        )
        data = graphql(q, api_key)
        batch = (data.get("data") or {}).get("transcripts") or []

        if not batch:
            break

        # Transcripts are returned newest-first; stop when we go past start_ms
        relevant = [t for t in batch if t.get("date") and start_ms <= t["date"] <= end_ms]
        all_transcripts.extend(relevant)

        oldest_in_batch = min((t["date"] for t in batch if t.get("date")), default=0)
        if oldest_in_batch < start_ms or len(batch) < limit:
            break

        skip += limit

    return sorted(all_transcripts, key=lambda t: t["date"], reverse=True)


# ── Parsing helpers ────────────────────────────────────────────────────────────

def extract_timestamp(text):
    m = re.search(r"\((\d{1,2}:\d{2}(?::\d{2})?)\)\s*$", text.strip())
    return m.group(1) if m else "—"


def strip_timestamp(text):
    return re.sub(r"\s*\(\d{1,2}:\d{2}(?::\d{2})?\)\s*$", "", text.strip()).strip()


def extract_eta(text):
    for pat in ETA_PATTERNS:
        m = re.search(pat, text.lower())
        if m:
            start = max(0, m.start() - 3)
            end = min(len(text), m.end() + 25)
            return text[start:end].strip().rstrip(".,;)")
    return "—"


def parse_action_items(raw):
    """Return list of (owner, action_text, timestamp, eta, is_mine)."""
    items = []
    current_owner = None
    for line in raw.split("\n"):
        line = line.strip()
        if not line:
            continue
        if line.startswith("**") and line.endswith("**"):
            current_owner = line.strip("*").strip()
            continue
        ts = extract_timestamp(line)
        clean = strip_timestamp(line)
        eta = extract_eta(clean)
        is_mine = bool(current_owner and any(v in current_owner.lower() for v in MY_NAME_VARIANTS))
        items.append((current_owner or "—", clean, ts, eta, is_mine))
    return items


# ── Renderers ─────────────────────────────────────────────────────────────────

def render_meeting_notes(transcripts):
    out = []
    out.append(f"# Meeting Notes\n")
    out.append(f"**{len(transcripts)} meetings**\n")
    out.append("---\n")

    for i, t in enumerate(transcripts, 1):
        title = t.get("title") or "Untitled"
        date_str = datetime.datetime.fromtimestamp(t["date"] / 1000).strftime("%Y-%m-%d %H:%M")
        participants = t.get("participants") or []
        summary = t.get("summary") or {}
        overview = (summary.get("overview") or "").strip()
        action_items_raw = (summary.get("action_items") or "").strip()

        out.append(f"## {i}. {title}")
        out.append(f"**Date:** {date_str}  ")
        out.append(f"**Participants:** {', '.join(participants)}\n")

        out.append("### Executive Summary")
        out.append(overview if overview else "_No summary available._")
        out.append("")

        out.append("### Action Items")
        if action_items_raw:
            items = parse_action_items(action_items_raw)
            prev_owner = None
            for owner, action, ts, eta, is_mine in items:
                if owner != prev_owner:
                    out.append(f"\n**{owner}**")
                    prev_owner = owner
                out.append(f"- **{action}**" if is_mine else f"- {action}")
        else:
            out.append("_No action items recorded._")

        out.append("\n---\n")

    return "\n".join(out)


def render_action_items(transcripts, mine_only=False):
    from itertools import groupby

    rows = []
    for t in transcripts:
        title = t.get("title") or "Untitled"
        date_str = datetime.datetime.fromtimestamp(t["date"] / 1000).strftime("%Y-%m-%d")
        summary = t.get("summary") or {}
        raw = (summary.get("action_items") or "").strip()
        if not raw:
            continue
        for owner, action, ts, eta, is_mine in parse_action_items(raw):
            if mine_only and not is_mine:
                continue
            rows.append({"date": date_str, "topic": title, "owner": owner,
                         "action": action, "time": ts, "eta": eta, "is_mine": is_mine})

    total = len(rows)
    mine_count = sum(1 for r in rows if r["is_mine"])

    out = []
    out.append("# Action Items\n")
    out.append(f"**{total} action items** | **{mine_count} assigned to Jagadesh**\n")
    out.append("> Bold rows = assigned to Jagadesh Thangavelu\n")
    out.append("---\n")

    for (date, topic), group in groupby(rows, key=lambda r: (r["date"], r["topic"])):
        items = list(group)
        out.append(f"## {date} — {topic}\n")
        out.append("| Owner / DRI | Action | Time | ETA |")
        out.append("|---|---|---|---|")
        for r in items:
            action = r["action"].replace("|", "\\|")
            owner = r["owner"].replace("|", "\\|")
            eta = r["eta"].replace("|", "\\|")
            if r["is_mine"]:
                out.append(f"| **{owner}** | **{action}** | {r['time']} | {eta} |")
            else:
                out.append(f"| {owner} | {action} | {r['time']} | {eta} |")
        out.append("")

    return "\n".join(out)


# ── CLI ────────────────────────────────────────────────────────────────────────

def parse_args():
    parser = argparse.ArgumentParser(
        description="Fetch Fireflies meeting summaries for a date range.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    date_group = parser.add_mutually_exclusive_group()
    date_group.add_argument(
        "--days", type=int, default=None, metavar="N",
        help="Last N days (default: 60)",
    )
    date_group.add_argument(
        "--start", type=str, default=None, metavar="YYYY-MM-DD",
        help="Start date (inclusive)",
    )
    parser.add_argument(
        "--end", type=str, default=None, metavar="YYYY-MM-DD",
        help="End date inclusive (default: today); only valid with --start",
    )
    parser.add_argument(
        "--mode", choices=["notes", "actions", "both"], default="both",
        help="Output mode (default: both)",
    )
    parser.add_argument(
        "--mine", action="store_true",
        help="In action items output, show only Jagadesh's items",
    )
    parser.add_argument(
        "--out", type=str, default=None, metavar="FILE",
        help="Write output to FILE instead of stdout",
    )
    return parser.parse_args()


def resolve_dates(args):
    today = datetime.datetime.now().replace(hour=23, minute=59, second=59, microsecond=0)

    if args.start:
        try:
            start = datetime.datetime.strptime(args.start, "%Y-%m-%d")
        except ValueError:
            sys.exit(f"Invalid --start date: {args.start!r} (expected YYYY-MM-DD)")
        if args.end:
            try:
                end = datetime.datetime.strptime(args.end, "%Y-%m-%d").replace(
                    hour=23, minute=59, second=59
                )
            except ValueError:
                sys.exit(f"Invalid --end date: {args.end!r} (expected YYYY-MM-DD)")
        else:
            end = today
    else:
        if args.end:
            sys.exit("--end requires --start")
        days = args.days if args.days is not None else 60
        end = today
        start = today - datetime.timedelta(days=days)

    if start > end:
        sys.exit(f"--start ({args.start}) must be before --end ({args.end})")

    return int(start.timestamp() * 1000), int(end.timestamp() * 1000)


def main():
    args = parse_args()
    start_ms, end_ms = resolve_dates(args)

    start_str = datetime.datetime.fromtimestamp(start_ms / 1000).strftime("%Y-%m-%d")
    end_str = datetime.datetime.fromtimestamp(end_ms / 1000).strftime("%Y-%m-%d")

    print(f"Fetching meetings {start_str} → {end_str} ...", file=sys.stderr)

    api_key = load_api_key()
    transcripts = fetch_transcripts(api_key, start_ms, end_ms)

    print(f"Found {len(transcripts)} meetings.", file=sys.stderr)

    sections = []

    if args.mode in ("notes", "both"):
        sections.append(render_meeting_notes(transcripts))

    if args.mode in ("actions", "both"):
        sections.append(render_action_items(transcripts, mine_only=args.mine))

    output = "\n\n".join(sections)

    if args.out:
        with open(os.path.expanduser(args.out), "w") as f:
            f.write(output)
        print(f"Written to {args.out}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
