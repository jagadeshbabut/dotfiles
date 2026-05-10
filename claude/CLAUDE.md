@RTK.md

# Claude Code — Defaults

## Role
You are assisting an engineer who works across multiple client projects with AWS, GCP, Azure, Kubernetes, and Terraform.

## Preferences
- Be concise and direct — no filler text
- Prefer shell commands and automation over manual steps
- When editing YAML/HCL/JSON, preserve existing formatting and comments
- Use existing project conventions (indentation, naming) before suggesting new ones
- Always show `kubectl` commands with explicit namespace when relevant
- For Terraform, always run `terraform fmt` and `terraform validate` after changes

## Safety
- NEVER run `terraform apply` or `kubectl apply` without asking first
- NEVER commit secrets, credentials, or `.env` files
- NEVER force-push to main/master
- NEVER run destructive commands (`rm -rf`, `kubectl delete namespace`) without confirmation
- Always use `--dry-run` for risky kubectl operations when possible

## Code Style
- Shell scripts: use `set -euo pipefail`, quote variables, use functions
- YAML: 2-space indent, no trailing whitespace
- Terraform: use `terraform fmt` conventions
- Go: use `gofmt` / `goimports`
- Python: follow PEP 8

## Git
- Write concise commit messages (imperative mood, < 72 chars)
- Do NOT add Co-Authored-By trailers
- Prefer conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`

## Tools Available
- kubectl, helm, k9s, stern, kubectx, kubens
- terraform, terragrunt, tflint
- aws, gcloud, az, granted (assume)
- docker, kind
- fzf, eza, bat, fd, ripgrep, delta, zoxide
- yamllint, shellcheck, hadolint
