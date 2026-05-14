#!/bin/bash
set -uo pipefail

DOTFILES="$HOME/personal/dotfiles"
OUTPUT_FILE="$DOTFILES/logs/sync_work_repos.log"
WORK_DIR="$HOME/work"
CONF_FILE="$DOTFILES/launchd/sync_work_repos.conf"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$OUTPUT_FILE"
}

mkdir -p "$DOTFILES/logs"
log "=== sync work repos started ==="

if [[ ! -f "$CONF_FILE" ]]; then
    cp "$DOTFILES/launchd/sync_work_repos.conf.template" "$CONF_FILE"
    log "WARN no conf found — created $CONF_FILE from template. Edit it to add repos."
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
    default_branch=$(git -C "$repo_path" remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')
    default_branch="${default_branch:-main}"
    if git -C "$repo_path" fetch origin "$default_branch" >> "$OUTPUT_FILE" 2>&1; then
        if git -C "$repo_path" merge --ff-only "origin/$default_branch" >> "$OUTPUT_FILE" 2>&1; then
            log "OK $repo pulled to $(git -C "$repo_path" rev-parse --short HEAD)"
        else
            log "WARN $repo has local commits ahead of origin/$default_branch — skipping merge"
        fi
    else
        log "ERROR $repo fetch failed"
    fi
done < "$CONF_FILE"

log "=== sync work repos finished ==="
