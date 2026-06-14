#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
repo=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
branch=$(echo "$input" | jq -r '.worktree.branch // empty')
if [ -z "$branch" ]; then
  branch=$(git -C "$(echo "$input" | jq -r '.workspace.current_dir')" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || true)
fi
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ANSI colors
RESET="\033[0m"
DIM="\033[2m"
RED="\033[31m"
CYAN="\033[36m"
YELLOW="\033[33m"
GREEN="\033[32m"

parts=""

# Model
parts="${parts}$(printf "${DIM}%s${RESET}" "$model")"

# Repo
if [ -n "$repo" ]; then
  parts="${parts}$(printf "  ${CYAN}%s${RESET}" "$repo")"
fi

# Branch
if [ -n "$branch" ]; then
  parts="${parts}$(printf "  ${YELLOW}%s${RESET}" "$branch")"
fi

# Context %
if [ -n "$used_pct" ]; then
  int_pct=$(printf "%.0f" "$used_pct")
  if [ "$int_pct" -gt 70 ]; then
    ctx_color="$RED"
  else
    ctx_color="$GREEN"
  fi
  parts="${parts}$(printf "  ${ctx_color}ctx:%s%%${RESET}" "$int_pct")"
fi

printf "%b" "$parts"
