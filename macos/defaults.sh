#!/usr/bin/env bash
# macOS system preferences — run once on a fresh machine
# These match the current Jaga setup as of 2025.

set -euo pipefail

echo "[INFO] Applying macOS defaults..."

# ── Dock ──────────────────────────────────────────────────────
# Position on left, autohide, 60px tiles
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 60
defaults write com.apple.dock show-recents -bool false

# ── Finder ────────────────────────────────────────────────────
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"   # List view
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true           # Show hidden files
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# ── Keyboard ──────────────────────────────────────────────────
# Fast key repeat (1 = fastest usable, 15 = default initial delay)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable autocorrect annoyances
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# ── Screenshots ───────────────────────────────────────────────
defaults write com.apple.screencapture location -string "$HOME/Desktop"
defaults write com.apple.screencapture type -string "png"

# ── Activity Monitor ─────────────────────────────────────────
# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# ── Restart affected apps ────────────────────────────────────
for app in Finder Dock SystemUIServer; do
    killall "$app" 2>/dev/null || true
done

echo "[OK] macOS defaults applied. Log out and back in for full effect."
