#!/bin/bash
set -uo pipefail

DOTFILES="$HOME/work/dotfiles"
LOG_FILE="$DOTFILES/logs/periodic_cleanup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

mkdir -p "$DOTFILES/logs"
log "=== periodic cleanup started ==="

# node_modules older than 30 days
log "--- node_modules cleanup ---"
for dir in "$HOME/work"; do
    [[ -d "$dir" ]] || continue
    find "$dir" -name "node_modules" -type d -prune -mtime +30 -print0 \
        | xargs -0 -r rm -rf
    log "node_modules cleaned in $dir"
done

# Ruby gems
log "--- gem cleanup ---"
if command -v gem &>/dev/null; then
    gem cleanup >> "$LOG_FILE" 2>&1
    log "gem cleanup done"
else
    log "SKIP gem — not installed"
fi

# CocoaPods cache
log "--- CocoaPods cache ---"
if [[ -d "$HOME/Library/Caches/CocoaPods" ]]; then
    rm -rf "$HOME/Library/Caches/CocoaPods"
    log "CocoaPods cache cleared"
else
    log "SKIP CocoaPods cache — not present"
fi

# Xcode cleanup
log "--- Xcode cleanup ---"
if command -v xcrun &>/dev/null; then
    xcrun simctl delete unavailable >> "$LOG_FILE" 2>&1
    log "unavailable simulators deleted"

    for xcode_dir in \
        "$HOME/Library/Developer/Xcode/Archives" \
        "$HOME/Library/Developer/Xcode/DerivedData" \
        "$HOME/Library/Developer/Xcode/iOS Device Logs"; do
        if [[ -d "$xcode_dir" ]]; then
            rm -rf "$xcode_dir"
            log "cleared: $xcode_dir"
        fi
    done
else
    log "SKIP Xcode cleanup — xcrun not found"
fi

log "=== periodic cleanup finished ==="
