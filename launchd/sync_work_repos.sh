#!/bin/bash
set -uo pipefail

LOG_DIR="$HOME/Library/Logs"
OUTPUT_FILE="$LOG_DIR/sync_work_repos.log"
WORK_DIR="$HOME/work"
CONF_FILE="$(cd "$(dirname "$0")" && pwd)/sync_work_repos.conf"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$OUTPUT_FILE"
}

mkdir -p "$LOG_DIR"
log "=== sync work repos started ==="

if [[ ! -f "$CONF_FILE" ]]; then
    log "ERROR config not found at $CONF_FILE — copy sync_work_repos.conf.template to sync_work_repos.conf"
    exit 1
fi

while IFS= read -r repo || [[ -n "$repo" ]]; do
    [[ "$repo" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${repo// }" ]] && continue

    repo_path="$WORK_DIR/$repo"
    if [[ ! -d "$repo_path" ]]; then
        log "SKIP $repo — not found at $repo_path"
        continue
    fi

    log "--- $repo ---"
    if git -C "$repo_path" fetch origin main >> "$OUTPUT_FILE" 2>&1; then
        if git -C "$repo_path" merge --ff-only origin/main >> "$OUTPUT_FILE" 2>&1; then
            log "OK $repo pulled to $(git -C "$repo_path" rev-parse --short HEAD)"
        else
            log "WARN $repo has local commits ahead of origin/main — skipping merge"
        fi
    else
        log "ERROR $repo fetch failed"
    fi
done < "$CONF_FILE"

log "=== sync work repos finished ==="
