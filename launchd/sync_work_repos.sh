#!/bin/bash
set -uo pipefail

DOTFILES="$HOME/Work/dotfiles"
OUTPUT_FILE="$DOTFILES/logs/sync_work_repos.log"
WORK_DIR="$HOME/Work"
CONF_FILE="$DOTFILES/launchd/sync_work_repos.conf"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$OUTPUT_FILE"
}

run_with_timeout() {
    local secs=$1; shift
    "$@" &
    local pid=$!
    ( sleep "$secs" && kill "$pid" 2>/dev/null ) &
    local timer=$!
    wait "$pid" 2>/dev/null
    local exit_code=$?
    kill "$timer" 2>/dev/null
    wait "$timer" 2>/dev/null
    return $exit_code
}

mkdir -p "$DOTFILES/logs"
log "=== sync work repos started ==="

if [[ ! -f "$CONF_FILE" ]]; then
    cp "$DOTFILES/launchd/sync_work_repos.conf.template" "$CONF_FILE"
    log "WARN no conf found — created $CONF_FILE from template. Edit it to add repos."
fi

failed_repos=()
skipped_repos=()

while IFS= read -r repo || [[ -n "$repo" ]]; do
    [[ "$repo" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${repo// }" ]] && continue

    repo_path="$WORK_DIR/$repo"
    if [[ ! -d "$repo_path" ]]; then
        log "SKIP $repo — not found at $repo_path"
        skipped_repos+=("$repo")
        continue
    fi

    log "--- $repo ---"
    default_branch=$(git -C "$repo_path" remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')
    default_branch="${default_branch:-main}"
    if run_with_timeout 120 git -C "$repo_path" fetch origin "$default_branch" >> "$OUTPUT_FILE" 2>&1; then
        if git -C "$repo_path" merge --ff-only "origin/$default_branch" >> "$OUTPUT_FILE" 2>&1; then
            log "OK $repo pulled to $(git -C "$repo_path" rev-parse --short HEAD)"
        else
            log "WARN $repo has local commits ahead of origin/$default_branch — skipping merge"
        fi
    else
        log "ERROR $repo fetch failed"
        failed_repos+=("$repo")
    fi
done < "$CONF_FILE"

if [[ ${#failed_repos[@]} -gt 0 || ${#skipped_repos[@]} -gt 0 ]]; then
    log "--- summary ---"
    if [[ ${#failed_repos[@]} -gt 0 ]]; then
        for r in "${failed_repos[@]}"; do
            log "FAILED $r"
        done
    fi
    if [[ ${#skipped_repos[@]} -gt 0 ]]; then
        for r in "${skipped_repos[@]}"; do
            log "SKIPPED $r"
        done
    fi
fi

log "=== sync work repos finished ==="
