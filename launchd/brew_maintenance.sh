#!/bin/bash
set -uo pipefail

DOTFILES="$HOME/personal/dotfiles"
LOG_FILE="$DOTFILES/logs/brew_maintenance.log"
BREW="/opt/homebrew/bin/brew"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

mkdir -p "$DOTFILES/logs"
log "=== brew maintenance started ==="

log "--- brew update ---"
$BREW update >> "$LOG_FILE" 2>&1

log "--- brew upgrade ---"
$BREW upgrade >> "$LOG_FILE" 2>&1

log "--- brew cleanup ---"
$BREW cleanup >> "$LOG_FILE" 2>&1

log "--- brew doctor ---"
$BREW doctor >> "$LOG_FILE" 2>&1 || true

log "=== brew maintenance finished ==="
