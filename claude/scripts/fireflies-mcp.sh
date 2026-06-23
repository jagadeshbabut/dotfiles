#!/usr/bin/env bash
set -euo pipefail
API_KEY="$(cat "$HOME/.config/fireflies/api_key")"
exec npx -y mcp-remote "https://api.fireflies.ai/mcp" \
  --header "Authorization: Bearer ${API_KEY}"
