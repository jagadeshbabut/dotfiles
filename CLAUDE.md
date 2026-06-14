# dotfiles — Claude Code Instructions

## Core Rule: Dotfiles Are the Source of Truth

The real file always lives in this repo. The home directory holds a symlink.

**Never** create or edit a file directly in `~/.config/`, `~/.claude/`, etc. Always:
1. Create/edit the file in the appropriate `dotfiles/<tool>/` subdirectory
2. Symlink it into place via `install.sh`

## Paths: Always Use Variables, Never Hardcode

- Use `$HOME` or `$DOTFILES` — never `/Users/jaga/` or any absolute path
- `$DOTFILES` is set by `install.sh` to the repo root at runtime
- In config files that don't support shell variables, use `install.sh` to expand `$HOME` at install time (see the `settings.json` pattern with `sed`)

## After Any Change: Rerun install.sh

Always run `./install.sh` after making any change to dotfiles — adding files, editing configs, updating `install.sh` itself. This ensures symlinks are in place and nothing is left as a stale or missing link.

```bash
cd /Users/jaga/Work/dotfiles && ./install.sh --yes
```

## Adding a New File

1. Place the file in `dotfiles/<tool>/<file>`
2. Add a `create_symlink` call in `install.sh` in the relevant section
3. If the file is executable (scripts, hooks), add `chmod +x` immediately after
4. If the file contains hardcoded paths, add a `sed` expansion step (see claude `settings.json` block)

### install.sh pattern

```bash
create_symlink "$DOTFILES/<tool>/<file>" "$HOME/.<target>/<file>"
chmod +x "$HOME/.<target>/<file>"   # only if executable
```

## install.sh Conventions

- Group symlinks by tool (fish, claude, git, etc.) with a `# ── Section ──` comment header
- Use `create_symlink src dest` — it handles backup, removes stale symlinks, creates parent dirs
- Run `./install.sh --yes` for non-interactive installs (CI, fresh machine)

## Claude-Specific (`dotfiles/claude/`)

Files that land in `~/.claude/`:

| Dotfiles path | Symlink target |
|---|---|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/RTK.md` | `~/.claude/RTK.md` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` |
| `claude/hooks/rtk-rewrite.sh` | `~/.claude/hooks/rtk-rewrite.sh` |
| `claude/commands/<name>.md` | `~/.claude/commands/<name>.md` |
| `claude/scripts/<name>` | `~/.claude/scripts/<name>` |
| `claude/skills/<name>/` | `~/.claude/skills/<name>/` |
| `claude/themes/<name>` | `~/.claude/themes/<name>` |

`settings.json` uses `sed "$HOME"` expansion at install time instead of a direct symlink (Claude Code resolves `$HOME` in the command field but not everywhere).

## Safety

- Never commit secrets, tokens, or credentials
- `.gitignore` excludes `*.env`, `*.pem`, `*.key`, and similar
- Run `./install.sh` on a fresh machine to verify everything wires up correctly
