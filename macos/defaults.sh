#!/usr/bin/env bash
# macOS system preferences — run once on a fresh machine.
# Usage: ./macos/defaults.sh [--yes]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         macOS Defaults                       ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
warn "This will change macOS system settings."
warn "A logout/restart is recommended after running."
if [[ "${1:-}" != "--yes" ]]; then
    read -p "Continue? (y/n) " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

# ══════════════════════════════════════════════════════════════
# Keyboard
# ══════════════════════════════════════════════════════════════
info "Configuring keyboard..."

defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

success "Keyboard configured"

# ══════════════════════════════════════════════════════════════
# Dock
# ══════════════════════════════════════════════════════════════
info "Configuring Dock..."

defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock tilesize -int 60
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.2
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock launchanim -bool false

success "Dock configured"

# ══════════════════════════════════════════════════════════════
# Finder
# ══════════════════════════════════════════════════════════════
info "Configuring Finder..."

defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
chflags nohidden ~/Library 2>/dev/null || true
sudo chflags nohidden /Volumes 2>/dev/null || true

success "Finder configured"

# ══════════════════════════════════════════════════════════════
# Trackpad & Mission Control
# ══════════════════════════════════════════════════════════════
info "Configuring Trackpad & Mission Control..."

defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.dock mru-spaces -bool false

success "Trackpad & Mission Control configured"

# ══════════════════════════════════════════════════════════════
# Screenshots
# ══════════════════════════════════════════════════════════════
info "Configuring Screenshots..."

mkdir -p "$HOME/screenshots"
defaults write com.apple.screencapture location -string "$HOME/screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

success "Screenshots → ~/screenshots"

# ══════════════════════════════════════════════════════════════
# Privacy
# ══════════════════════════════════════════════════════════════
info "Hardening privacy..."

defaults write com.apple.Siri UserHasDeclinedEnable -bool true
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
defaults write com.apple.AdLib forceLimitAdTracking -bool true
defaults write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false
defaults write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false
defaults -currentHost write com.apple.Bluetooth PrefKeyServicesEnabled -bool false 2>/dev/null || true
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false 2>/dev/null || true
defaults write com.apple.airport.preferences RememberRecentNetworks -bool false 2>/dev/null || true

success "Privacy hardened"

# ══════════════════════════════════════════════════════════════
# Security & Firewall
# ══════════════════════════════════════════════════════════════
info "Configuring Security..."

sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on 2>/dev/null || warn "Could not enable firewall (run with sudo)"
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on 2>/dev/null || warn "Could not enable stealth mode"

success "Security configured"

# ══════════════════════════════════════════════════════════════
# Network (DNS)
# ══════════════════════════════════════════════════════════════
info "Configuring DNS..."

networksetup -setdnsservers Wi-Fi 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 2>/dev/null || warn "Could not set Wi-Fi DNS (check interface name)"

success "DNS set to 1.1.1.1 / 8.8.8.8"

# ══════════════════════════════════════════════════════════════
# Misc
# ══════════════════════════════════════════════════════════════
info "Configuring misc settings..."

defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.LaunchServices LSQuarantine -bool false

success "Misc settings configured"

# ══════════════════════════════════════════════════════════════
# Apply
# ══════════════════════════════════════════════════════════════
echo ""
info "Restarting affected apps..."

for app in Finder Dock SystemUIServer; do
    killall "$app" 2>/dev/null && success "Restarted $app" || true
done

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         macOS Defaults Applied!              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
warn "Log out and back in for keyboard repeat changes to take effect."
info "To revert any setting: defaults delete <domain> <key>"
echo ""
