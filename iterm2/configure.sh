#!/usr/bin/env bash
# iTerm2 setup — links the Jaga dynamic profile and applies global settings.
# Usage: ./iterm2/configure.sh [--yes]

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

if ! ls /Applications/iTerm.app &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} iTerm2 not installed. Run: brew install --cask iterm2"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         iTerm2 — Jaga Setup                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

if [[ "${1:-}" != "--yes" ]]; then
    read -p "Continue? (y/n) " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

# ── Dynamic Profile ───────────────────────────────────────────
# iTerm2 hot-reloads DynamicProfiles — no restart needed.
info "Linking Jaga dynamic profile..."

DYNAMIC_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
mkdir -p "$DYNAMIC_DIR"

if [[ -L "$DYNAMIC_DIR/Jaga.json" ]]; then
    rm "$DYNAMIC_DIR/Jaga.json"
elif [[ -f "$DYNAMIC_DIR/Jaga.json" ]]; then
    mv "$DYNAMIC_DIR/Jaga.json" "$DYNAMIC_DIR/Jaga.json.bak"
    warn "Backed up existing Jaga.json"
fi

ln -sf "$DOTFILES/iterm2/Jaga.json" "$DYNAMIC_DIR/Jaga.json"
success "Jaga profile linked → $DYNAMIC_DIR/Jaga.json"

# ── Global Settings ───────────────────────────────────────────
info "Applying global iTerm2 settings..."

# Don't prompt on quit
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

# Hide tab bar when only one tab is open
defaults write com.googlecode.iterm2 HideTab -bool true

# Dim inactive split panes (40%)
defaults write com.googlecode.iterm2 SplitPaneDimmingAmount -float 0.4

# Focus follows mouse between split panes
defaults write com.googlecode.iterm2 FocusFollowsMouse -bool true

# Don't load prefs from a custom folder (profile is managed via DynamicProfiles)
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool false

success "Global settings applied"

# ── Fish Shell Integration ────────────────────────────────────
info "Installing iTerm2 fish shell integration..."

FISH_INTEGRATION="$HOME/.iterm2_shell_integration.fish"
if [[ ! -f "$FISH_INTEGRATION" ]]; then
    curl -sL https://iterm2.com/shell_integration/fish -o "$FISH_INTEGRATION"
    success "Fish shell integration installed at $FISH_INTEGRATION"

    # Add source line to local.fish if not already there
    LOCAL_FISH="$HOME/.config/fish/local.fish"
    if [[ -f "$LOCAL_FISH" ]] && ! grep -q "iterm2_shell_integration" "$LOCAL_FISH"; then
        echo "" >> "$LOCAL_FISH"
        echo "# iTerm2 shell integration" >> "$LOCAL_FISH"
        echo "test -e ~/.iterm2_shell_integration.fish && source ~/.iterm2_shell_integration.fish" >> "$LOCAL_FISH"
        success "Added shell integration source to $LOCAL_FISH"
    fi
else
    success "Fish shell integration already installed"
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║       iTerm2 Configuration Complete!         ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
info "Profile 'Jaga' is live — select it in iTerm2 → Profiles."
info "Profile settings:"
echo "  - Shell:       fish (/opt/homebrew/bin/fish)"
echo "  - Working dir: ~/slice"
echo "  - Font:        Monaco 13"
echo "  - Size:        200 × 40"
echo "  - Scrollback:  Unlimited"
echo "  - Transparency: 5%  Blur: 10px"
echo "  - Option keys: Esc+ (word jump with Option+←/→)"
echo "  - Cursor:      blinking bar"
echo "  - Colors:      custom dark theme (embedded in profile)"
echo ""
warn "Relaunch iTerm2 if the profile doesn't appear immediately."
echo ""
