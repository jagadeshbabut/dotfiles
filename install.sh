#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║           dotfiles — One-Command Installer                   ║
# ║                                                              ║
# ║   Usage: git clone <repo> ~/personal/dotfiles                ║
# ║          cd ~/personal/dotfiles && ./install.sh              ║
# ║   One-click: ./install.sh --yes                              ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

AUTO_YES=false
[[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]] && AUTO_YES=true

confirm() {
    if [[ "$AUTO_YES" == true ]]; then return 0; fi
    read -p "$1 (y/n) " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]]
}

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         dotfiles Installer                   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

[[ "$(uname)" == "Darwin" ]] || { error "macOS only."; exit 1; }

# ── Step 1: Homebrew ──────────────────────────────────────────
info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    success "Homebrew installed"
else
    success "Homebrew already installed"
fi

# ── Step 2: Brew bundle ───────────────────────────────────────
info "Installing tools from Brewfile..."
if brew bundle --file="$DOTFILES/Brewfile"; then
    success "Brew packages installed"
else
    warn "Some Brewfile dependencies failed — run 'brew bundle install' manually to retry"
fi

# ── Step 3: Backup existing configs ──────────────────────────
info "Backing up existing configs to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
    local file="$1"
    if [[ -e "$file" && ! -L "$file" ]]; then
        cp -r "$file" "$BACKUP_DIR/" 2>/dev/null && warn "Backed up $file"
    fi
}

backup_if_exists "$HOME/.config/fish/config.fish"
backup_if_exists "$HOME/.config/starship.toml"
backup_if_exists "$HOME/.gitconfig"
backup_if_exists "$HOME/.gitignore_global"
backup_if_exists "$HOME/.ssh/config"
backup_if_exists "$HOME/.aws/config"
backup_if_exists "$HOME/.config/karabiner/karabiner.json"

# ── Step 4: Symlinks ─────────────────────────────────────────
info "Creating symlinks..."

create_symlink() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [[ -L "$dest" ]]; then
        rm "$dest"
    elif [[ -e "$dest" ]]; then
        mv "$dest" "$BACKUP_DIR/"
    fi
    ln -sf "$src" "$dest"
    success "Linked $dest → $src"
}

# Fish shell
create_symlink "$DOTFILES/fish/config.fish"                        "$HOME/.config/fish/config.fish"
create_symlink "$DOTFILES/fish/conf.d/virtualfish-loader.fish"     "$HOME/.config/fish/conf.d/virtualfish-loader.fish"
create_symlink "$DOTFILES/fish/conf.d/fish_frozen_key_bindings.fish" "$HOME/.config/fish/conf.d/fish_frozen_key_bindings.fish"
create_symlink "$DOTFILES/fish/conf.d/fish_frozen_theme.fish"      "$HOME/.config/fish/conf.d/fish_frozen_theme.fish"
create_symlink "$DOTFILES/fish/functions/aws-login.fish"           "$HOME/.config/fish/functions/aws-login.fish"
create_symlink "$DOTFILES/fish/functions/aws-status.fish"          "$HOME/.config/fish/functions/aws-status.fish"
create_symlink "$DOTFILES/fish/functions/fish_prompt.fish"         "$HOME/.config/fish/functions/fish_prompt.fish"
create_symlink "$DOTFILES/fish/functions/fish_right_prompt.fish"   "$HOME/.config/fish/functions/fish_right_prompt.fish"
create_symlink "$DOTFILES/fish/functions/__warp_block.fish"        "$HOME/.config/fish/functions/__warp_block.fish"
create_symlink "$DOTFILES/fish/aliases.fish"                       "$HOME/.config/fish/aliases.fish"

# Functions
create_symlink "$DOTFILES/fish/functions/ctx.fish"           "$HOME/.config/fish/functions/ctx.fish"
create_symlink "$DOTFILES/fish/functions/ns.fish"            "$HOME/.config/fish/functions/ns.fish"
create_symlink "$DOTFILES/fish/functions/decode-secret.fish" "$HOME/.config/fish/functions/decode-secret.fish"
create_symlink "$DOTFILES/fish/functions/kgetall.fish"       "$HOME/.config/fish/functions/kgetall.fish"
create_symlink "$DOTFILES/fish/functions/kexf.fish"          "$HOME/.config/fish/functions/kexf.fish"
create_symlink "$DOTFILES/fish/functions/klogf.fish"         "$HOME/.config/fish/functions/klogf.fish"
create_symlink "$DOTFILES/fish/functions/kevents.fish"       "$HOME/.config/fish/functions/kevents.fish"
create_symlink "$DOTFILES/fish/functions/kpff.fish"          "$HOME/.config/fish/functions/kpff.fish"
create_symlink "$DOTFILES/fish/functions/aws-profile.fish"   "$HOME/.config/fish/functions/aws-profile.fish"
create_symlink "$DOTFILES/fish/functions/aws-console.fish"   "$HOME/.config/fish/functions/aws-console.fish"
create_symlink "$DOTFILES/fish/functions/port.fish"          "$HOME/.config/fish/functions/port.fish"
create_symlink "$DOTFILES/fish/functions/mkcd.fish"          "$HOME/.config/fish/functions/mkcd.fish"
create_symlink "$DOTFILES/fish/functions/extract.fish"       "$HOME/.config/fish/functions/extract.fish"
create_symlink "$DOTFILES/fish/functions/jsonclip.fish"      "$HOME/.config/fish/functions/jsonclip.fish"
create_symlink "$DOTFILES/fish/functions/y2j.fish"           "$HOME/.config/fish/functions/y2j.fish"
create_symlink "$DOTFILES/fish/functions/j2y.fish"           "$HOME/.config/fish/functions/j2y.fish"
create_symlink "$DOTFILES/fish/functions/b64e.fish"          "$HOME/.config/fish/functions/b64e.fish"
create_symlink "$DOTFILES/fish/functions/b64d.fish"          "$HOME/.config/fish/functions/b64d.fish"
create_symlink "$DOTFILES/fish/functions/retry.fish"         "$HOME/.config/fish/functions/retry.fish"
create_symlink "$DOTFILES/fish/functions/watchurl.fish"      "$HOME/.config/fish/functions/watchurl.fish"

# Starship
create_symlink "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"

# Git
create_symlink "$DOTFILES/git/.gitconfig"          "$HOME/.gitconfig"
create_symlink "$DOTFILES/git/.gitconfig-personal" "$HOME/.gitconfig-personal"
create_symlink "$DOTFILES/git/.gitignore_global"   "$HOME/.gitignore_global"

# SSH
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
create_symlink "$DOTFILES/ssh/config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

# AWS
mkdir -p "$HOME/.aws"
create_symlink "$DOTFILES/aws/config" "$HOME/.aws/config"

# Karabiner
create_symlink "$DOTFILES/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
create_symlink "$DOTFILES/yamllint/.yamllint.yml"   "$HOME/.yamllint.yml"

# ── Step 5: Set fish as default shell ─────────────────────────
FISH_PATH="$(which fish)"
if confirm "Set fish as default shell ($FISH_PATH)?"; then
    if ! grep -qF "$FISH_PATH" /etc/shells; then
        echo "$FISH_PATH" | sudo tee -a /etc/shells
    fi
    chsh -s "$FISH_PATH"
    success "Default shell set to fish"
fi

# ── Step 6: Create fish local config (for secrets/overrides) ──
LOCAL_FISH="$HOME/.config/fish/local.fish"
if [[ ! -f "$LOCAL_FISH" ]]; then
    cat > "$LOCAL_FISH" << 'EOF'
# Machine-local fish config — not tracked in git
# Add secrets, PATH additions, or host-specific settings here.
#
# Examples:
#   set -gx GITHUB_TOKEN "ghp_..."
#   set -gx ANTHROPIC_API_KEY "sk-ant-..."
#   fish_add_path "$HOME/bin"
EOF
    success "Created $LOCAL_FISH for local overrides (add secrets here)"
fi

# ── Step 7: MCP servers for Claude Code ──────────────────────
info "Setting up MCP servers for Claude Code..."

if [[ ! -f "$HOME/.mcp-env" ]]; then
    cp "$DOTFILES/mcp/.mcp-env.template" "$HOME/.mcp-env"
    chmod 600 "$HOME/.mcp-env"
    warn "Created ~/.mcp-env from template — fill in your API tokens"
else
    success "~/.mcp-env already exists"
fi

if command -v jq &>/dev/null; then
    MCP_SERVERS=$(sed "s|\${HOME}|$HOME|g" "$DOTFILES/mcp/claude-code.json")
    CLAUDE_JSON="$HOME/.claude.json"
    if [[ -f "$CLAUDE_JSON" ]]; then
        jq --argjson mcp "$MCP_SERVERS" '.mcpServers = $mcp' "$CLAUDE_JSON" > /tmp/claude.json.tmp \
            && mv /tmp/claude.json.tmp "$CLAUDE_JSON"
        success "MCP servers merged into ~/.claude.json"
    else
        echo "{\"mcpServers\": $MCP_SERVERS}" > "$CLAUDE_JSON"
        success "Created ~/.claude.json with MCP servers"
    fi
else
    warn "jq not found — skipping MCP config (install jq and re-run)"
fi

# ── Step 8: Claude Code config ───────────────────────────────
info "Setting up Claude Code config..."

mkdir -p "$HOME/.claude/hooks"
mkdir -p "$HOME/.claude/commands"
mkdir -p "$HOME/.claude/scripts"

# CLAUDE.md and RTK.md — symlink
create_symlink "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
create_symlink "$DOTFILES/claude/RTK.md"    "$HOME/.claude/RTK.md"

# settings.json — copy with $HOME expansion (hook path must be absolute)
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$CLAUDE_SETTINGS" && ! -L "$CLAUDE_SETTINGS" ]]; then
    cp "$CLAUDE_SETTINGS" "$BACKUP_DIR/claude-settings.json" 2>/dev/null && warn "Backed up $CLAUDE_SETTINGS"
fi
sed "s|\$HOME|$HOME|g" "$DOTFILES/claude/settings.json" > "$CLAUDE_SETTINGS"
success "Written $CLAUDE_SETTINGS (hook path expanded)"

# RTK rewrite hook
create_symlink "$DOTFILES/claude/hooks/rtk-rewrite.sh" "$HOME/.claude/hooks/rtk-rewrite.sh"
chmod +x "$HOME/.claude/hooks/rtk-rewrite.sh"

# Slash commands
create_symlink "$DOTFILES/claude/commands/github-repo-audit.md" "$HOME/.claude/commands/github-repo-audit.md"
create_symlink "$DOTFILES/claude/commands/incident-audit.md"    "$HOME/.claude/commands/incident-audit.md"
create_symlink "$DOTFILES/claude/commands/setup-aws-laptop.md"  "$HOME/.claude/commands/setup-aws-laptop.md"

# Scripts
create_symlink "$DOTFILES/claude/scripts/incident_audit.py" "$HOME/.claude/scripts/incident_audit.py"

success "Claude Code config installed"

# ── Step 9: iTerm2 ───────────────────────────────────────────
if ls /Applications/iTerm.app &>/dev/null; then
    if confirm "Configure iTerm2 (Main profile, global settings, fish integration)?"; then
        bash "$DOTFILES/iterm2/configure.sh" --yes
    fi
fi

# ── Step 10: macOS defaults ──────────────────────────────────
if confirm "Apply macOS defaults (Dock left, autohide, fast key repeat, Finder settings)?"; then
    bash "$DOTFILES/macos/defaults.sh"
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         Installation Complete!               ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
info "Backups saved to: $BACKUP_DIR"
echo ""
info "Next steps:"
echo "  1. Open a new terminal (fish shell)"
echo "  2. Add secrets to ~/.config/fish/local.fish (GITHUB_TOKEN, etc.)"
echo "  3. Run 'aws-login' to authenticate with AWS SSO"
echo "  4. Run 'assume <profile>' to switch AWS profiles"
echo "  5. Add SSH keys: ~/.ssh/id_ed25519 (work) and ~/.ssh/id_ed25519_personal (personal)"
echo ""
info "Quick reference:"
echo "  aws-login          → Authenticate all AWS SSO profiles"
echo "  aws-status         → Show active profile and token status"
echo "  assume             → Fuzzy AWS profile picker (via granted)"
echo "  assume <profile>   → Switch to a specific AWS profile"
echo "  k9s                → Kubernetes TUI"
echo ""
