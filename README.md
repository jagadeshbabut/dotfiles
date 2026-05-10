# jaga-dotfiles

Personal macOS setup — fish shell, starship prompt, AWS SSO via granted, Kubernetes tooling.

## Quick Start

```bash
git clone git@github-personal:jagadeshbabut/jaga-dotfiles.git ~/personal/jaga-dotfiles
cd ~/personal/jaga-dotfiles && ./install.sh
```

Open a new terminal. Done.

## What's Included

### Tools (Brewfile)

| Category | Tools |
|----------|-------|
| Shell & prompt | `fish` `starship` `figlet` `virtualfish` |
| AWS | `awscli` `granted` |
| Kubernetes | `kubernetes-cli` `k9s` |
| Languages | `go` `pyenv` `uv` `pnpm` |
| GitHub | `gh` `act` |
| Utilities | `rtk` `claude-cmd` `maccy` |
| Apps | `orbstack` |
| Fonts | JetBrains Mono Nerd Font |

### Shell (fish)

- **Starship prompt** — shows git, AWS profile, k8s context, python env
- **virtualfish** — Python virtual environment management in fish
- **Warp-style block separation** — blank line after each command
- **figlet banner** — `JAGA` displayed on new shell

### Prompt (Starship)

Shows what matters at a glance:

```
jaga-mbp ~/work/my-project  main !2  ⎈ staging:default  prod-banking (ap-south-1)
➜
```

- Hostname + directory
- Git branch + status
- Kubernetes context (with production highlighted)
- AWS profile (via granted)

## AWS & Cloud

Login every morning:

```bash
aws-login           # opens browser for SSO, authenticates all profiles
aws-status          # show active profile and token expiry
assume              # fuzzy profile picker
assume prod-banking # switch to specific profile
```

Profiles managed in `aws/config` (18 accounts across non-prod and prod).

## File Structure

```
~/personal/jaga-dotfiles/
├── install.sh              # One-command installer
├── Brewfile                # All tools (brew bundle)
├── fish/
│   ├── config.fish         # Main config (PATH, OrbStack, granted, starship)
│   ├── conf.d/
│   │   ├── virtualfish-loader.fish
│   │   ├── fish_frozen_key_bindings.fish
│   │   └── fish_frozen_theme.fish
│   └── functions/
│       ├── aws-login.fish  # Morning SSO login
│       ├── aws-status.fish # Show active profile + token status
│       ├── fish_prompt.fish     # Starship integration
│       ├── fish_right_prompt.fish
│       └── __warp_block.fish    # Blank line after commands
├── starship/starship.toml  # Prompt config (Nerd Font icons, k8s, AWS)
├── git/
│   ├── .gitconfig          # Work identity (slice-jagadesht)
│   ├── .gitconfig-personal # Personal identity (auto-applied in ~/personal/)
│   └── .gitignore_global   # Global gitignore
├── ssh/config              # Work + personal GitHub, OrbStack
├── aws/config              # 18 AWS SSO profiles (slice-sso)
├── karabiner/karabiner.json # Cmd↔Option swap for external keyboards
└── macos/defaults.sh       # Dock, Finder, keyboard speed settings
```

## Customization

### Secrets & local overrides

Edit `~/.config/fish/local.fish` (not tracked in git):

```fish
set -gx GITHUB_TOKEN "ghp_..."
set -gx ANTHROPIC_API_KEY "sk-ant-..."
fish_add_path "$HOME/bin"
```

### Karabiner (keyboard remapping)

The `karabiner/karabiner.json` swaps Cmd↔Option for two external keyboards
(vendor IDs 9610 and 14) to match the Mac layout muscle memory.
Karabiner-Elements reads this from `~/.config/karabiner/karabiner.json`.

### SSH keys

The SSH config expects:
- `~/.ssh/id_ed25519` — work GitHub key (add to github.com)
- `~/.ssh/jaga-personal` — personal GitHub key (add to github.com via `github-personal` host alias)
