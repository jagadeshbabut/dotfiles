# Command: /github-repo-audit

Audits all GitHub repositories across every organisation the authenticated user
belongs to. Reports repo name, URL, activity status, and last activity date.
Saves a CSV file for future reference.

---

## Input

Optional output path for the CSV file. Defaults to `~/github-repos-audit.csv`.

Examples:
> /github-repo-audit
> /github-repo-audit ~/documents/repos-2026.csv

---

## Execution Steps

### Step 1 — Verify gh CLI and authentication

Run the following and check the output:

```bash
/opt/homebrew/bin/gh auth status 2>&1 || gh auth status 2>&1
```

- If `gh` is not found, install it: `brew install gh`
- If not authenticated, tell the user to run: `gh auth login`
- If the `read:org` scope is missing, tell the user to run:
  `/opt/homebrew/bin/gh auth refresh -h github.com -s read:org`
  and wait for them to confirm before proceeding.
- Print the authenticated username and host before continuing.

### Step 2 — Discover all organisations

```bash
gh api /user/orgs --paginate --jq '.[].login'
```

Use the full path `/opt/homebrew/bin/gh` if `gh` is not in PATH.

Print the list of orgs found.

### Step 3 — Fetch all repos for every org

For each org, fetch all repos (including private, forked, archived):

```bash
gh api "/orgs/{org}/repos?type=all&per_page=100" --paginate \
  --jq '.[] | [.name, .html_url, .archived, .disabled, .pushed_at, .updated_at] | @tsv'
```

Collect results tagged with their org name. Handle API errors per org
gracefully — warn and skip rather than aborting.

### Step 4 — Parse and classify repos

Run the following Python script via Bash to produce the CSV:

```python
import csv, sys
from datetime import datetime, timedelta, timezone

# INPUT_LINES: list of "org\trepo\turl\tarchived\tdisabled\tpushed_at\tupdated_at" strings
# OUTPUT_PATH: path for the CSV (from user input or default ~/github-repos-audit.csv)

now = datetime.now(tz=timezone.utc)
cutoff_active = now - timedelta(days=180)   # 6 months
cutoff_stale  = now - timedelta(days=548)   # 18 months

def parse_dt(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except Exception:
        return datetime.min.replace(tzinfo=timezone.utc)

rows = []
for line in INPUT_LINES:
    parts = line.rstrip("\n").split("\t")
    if len(parts) < 7:
        continue
    org, repo, url, archived, disabled, pushed_at, updated_at = parts[:7]
    last_dt = max(parse_dt(pushed_at), parse_dt(updated_at))
    last_str = last_dt.strftime("%Y-%m-%d") if last_dt != datetime.min.replace(tzinfo=timezone.utc) else "Unknown"

    if archived == "true":
        status = "Archived"
    elif last_dt >= cutoff_active:
        status = "Active"
    elif last_dt >= cutoff_stale:
        status = "Stale (6-18 months)"
    else:
        status = "Inactive (>18 months)"

    rows.append([org, repo, url, status, last_str])

with open(OUTPUT_PATH, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["Org", "Repo", "URL", "Status", "Last Activity"])
    w.writerows(rows)
```

Important: the `cutoff_active` and `cutoff_stale` dates must be recomputed
at runtime relative to today's date (active = within 6 months, stale = 6–18
months, inactive = older than 18 months).

### Step 5 — Print summary to chat

After writing the CSV, print:

1. Total repos found and the output file path
2. A table of repos per org:

```
Org                             Repos
Buddy-Git                          50
ne-bank                           101
...
Total                             830
```

3. A table of status breakdown:

```
Status                          Count
Active                            381
Stale (6-18 months)                87
Inactive (>18 months)             268
Archived                           94
Total                             830
```

4. A short callout:
   - How many repos are candidates for cleanup (Inactive + Archived)
   - Which org has the most inactive repos

---

## Output Contract

- CSV file written to the specified or default path
- Summary table printed to chat
- CSV columns: `Org, Repo, URL, Status, Last Activity`

---

## Error Handling

- **gh not found**: instruct user to run `brew install gh`
- **Not authenticated**: instruct user to run `gh auth login`
- **Missing read:org scope**: instruct user to run `gh auth refresh -h github.com -s read:org`
- **Org fetch fails**: warn and skip that org, continue with others
- **No repos found at all**: print a clear error and stop

---

## Rules

- Always recompute the active/stale/inactive cutoff dates relative to the
  current date at runtime — do not hardcode dates
- Never print or log auth tokens
- This is a read-only audit — do not create, modify, or delete any repos
- If the CSV already exists at the output path, overwrite it with the latest data
