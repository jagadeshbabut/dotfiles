#!/bin/bash
set -uo pipefail

LOG_DIR="$HOME/Library/Logs"
OUTPUT_FILE="$LOG_DIR/brew_maintenance.log"
BREW="/opt/homebrew/bin/brew"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$OUTPUT_FILE"
}

mkdir -p "$LOG_DIR"
log "=== brew maintenance started ==="

log "--- brew update ---"
$BREW update >> "$OUTPUT_FILE" 2>&1

log "--- brew upgrade ---"
$BREW upgrade >> "$OUTPUT_FILE" 2>&1

log "--- brew cleanup ---"
$BREW cleanup >> "$OUTPUT_FILE" 2>&1

log "--- brew doctor ---"
$BREW doctor >> "$OUTPUT_FILE" 2>&1 || true

log "=== brew maintenance finished ==="
