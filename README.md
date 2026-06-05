# dotfiles

Personal macOS setup — fish shell, starship prompt, AWS SSO via granted, Kubernetes tooling.

## Quick Start

```bash
git clone git@github-personal:jagadeshbabut/dotfiles.git ~/work/dotfiles
cd ~/work/dotfiles && ./install.sh
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
| Apps | `maccy` |
| Fonts | JetBrains Mono Nerd Font |

### Shell (fish)

- **Starship prompt** — shows git, AWS profile, k8s context, python env
- **virtualfish** — Python virtual environment management in fish
- **Warp-style block separation** — blank line after each command
- **figlet banner** — hostname displayed on new shell

### Prompt (Starship)

Shows what matters at a glance:

```
your-mbp ~/work/my-project  main !2  ⎈ staging:default  prod-banking (ap-south-1)
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

## File Structure

```
~/work/dotfiles/
├── install.sh              # One-command installer
├── Brewfile                # All tools (brew bundle)
├── fish/
│   ├── config.fish         # Main config (PATH, granted, starship)
│   ├── aliases.fish        # Shell aliases (eza, bat, kubectl, git, docker, tf)
│   ├── conf.d/
│   │   ├── virtualfish-loader.fish
│   │   ├── fish_frozen_key_bindings.fish
│   │   └── fish_frozen_theme.fish
│   └── functions/
│       ├── aws-login.fish  # Morning SSO login
│       ├── aws-status.fish # Show active profile + token status
│       ├── aws-profile.fish / aws-console.fish
│       ├── ctx.fish / ns.fish  # fzf k8s context/namespace switchers
│       ├── kexf.fish / klogf.fish / kpff.fish / kgetall.fish / kevents.fish
│       ├── decode-secret.fish / jsonclip.fish
│       ├── b64e.fish / b64d.fish / y2j.fish / j2y.fish
│       ├── extract.fish / mkcd.fish / port.fish / retry.fish / watchurl.fish
│       ├── fish_prompt.fish / fish_right_prompt.fish
│       └── __warp_block.fish   # Blank line after commands
├── starship/starship.toml  # Prompt config (Nerd Font icons, k8s, AWS)
├── git/
│   ├── .gitconfig          # Work identity
│   ├── .gitconfig-personal # Personal GitHub identity (jagadeshbabut@gmail.com)
│   └── .gitignore_global   # Global gitignore
├── ssh/config              # Work + personal GitHub
├── karabiner/karabiner.json # Cmd↔Option swap for external keyboards
├── macos/defaults.sh       # Dock, Finder, keyboard speed settings
├── iterm2/
│   ├── Profile.json        # iTerm2 dynamic profile (fish, Monaco 13, Dracula)
│   ├── Dracula.itermcolors # Dracula color scheme
│   └── configure.sh        # Links profile, imports colors, sets global prefs
├── claude/
│   ├── CLAUDE.md           # Claude Code assistant defaults
│   ├── RTK.md              # RTK token-killer docs (referenced by CLAUDE.md)
│   ├── settings.json       # Claude Code settings + hook + permissions template
│   ├── hooks/rtk-rewrite.sh # PreToolUse hook: rewrites Bash cmds through rtk
│   ├── commands/           # Slash commands: /github-repo-audit, /incident-audit, /setup-aws-laptop
│   └── scripts/incident_audit.py
├── mcp/
│   ├── claude-code.json    # MCP server definitions (Atlassian, GitHub, k8s, Grafana, AWS, memory)
│   └── .mcp-env.template   # API token template — copy to ~/.mcp-env
├── templates/
│   └── .pre-commit-config.yaml  # Pre-commit hook config for infra projects
└── yamllint/
    └── .yamllint.yml       # yamllint config (symlinked to ~/.yamllint.yml)
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
- `~/.ssh/id_ed25519_personal` — personal GitHub key (add to github.com via `github-personal` host alias)
