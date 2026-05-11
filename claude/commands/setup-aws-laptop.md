Set up a complete AWS development environment on this machine. This includes Homebrew, AWS CLI, Granted, Fish shell integration, all AWS SSO profiles, and EKS kubeconfig for all clusters.

Work through each phase in order. Check if tools are already installed before installing. Tell the user what you're doing at each step.

---

## Phase 1 — Install Tools

### 1.1 Homebrew
Check if `brew` is installed. If not, install it:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
After install on Apple Silicon, run:
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 1.2 Core tools
Install these via brew if not already present:
```bash
brew install awscli granted fish kubectl
```
Verify with: `aws --version`, `granted --version`, `kubectl version --client`

---

## Phase 2 — AWS Config

`~/.aws/config` is managed by dotfiles — `install.sh` symlinks it from `aws/config` in the repo.

Check if the symlink is already in place:
```bash
ls -la ~/.aws/config
```

If it's a symlink pointing to the dotfiles repo, skip to Phase 3.

If it's missing or a plain file, run `install.sh` first, or manually symlink:
```bash
mkdir -p ~/.aws
ln -sf ~/personal/dotfiles/aws/config ~/.aws/config
```

Then fill in `aws/config` with your org's SSO portal URL, account IDs, and role names — one `[profile ...]` block per AWS account. See the file for the required structure.

---

## Phase 3 — Fish Shell Integration

### 3.1 Ensure directories exist
```bash
mkdir -p ~/.config/fish/functions
```

### 3.2 Add assume alias to config.fish
Check if `alias assume` already exists in `~/.config/fish/config.fish`. If not, append:
```fish
alias assume="source /opt/homebrew/bin/assume.fish"
```

### 3.3 Write ~/.config/fish/functions/aws-login.fish
```fish
function aws-login --description "Morning AWS SSO login - authenticates all profiles via work-sso"
    set -l sso_session "work-sso"
    set -l sso_url "https://YOUR_SSO_ID.awsapps.com/start/"

    echo "Logging into AWS SSO ($sso_session)..."
    echo "URL: $sso_url"
    echo ""

    aws sso login --sso-session $sso_session

    if test $status -eq 0
        echo ""
        echo "All profiles authenticated. Token valid for ~8 hours."
        echo ""
        echo "Switch profiles with:  assume <profile>"
        echo "Fuzzy pick with:       assume"
        echo ""
        echo "Available profiles:"
        aws configure list-profiles 2>/dev/null | sort | while read -l profile
            echo "  $profile"
        end
    else
        echo ""
        echo "Login failed. Run 'granted doctor' to diagnose."
        return 1
    end
end
```

### 3.4 Write ~/.config/fish/functions/aws-status.fish
```fish
function aws-status --description "Show active AWS profile and SSO token status"
    echo "=== AWS Status ==="

    if set -q AWS_PROFILE
        echo "Active profile : $AWS_PROFILE"
    else
        echo "Active profile : (none — run 'assume <profile>')"
    end

    if set -q AWS_REGION
        echo "Region         : $AWS_REGION"
    end

    if set -q AWS_SESSION_EXPIRATION
        echo "Expires        : $AWS_SESSION_EXPIRATION"
    end

    echo ""
    echo "SSO Tokens:"
    granted sso-tokens list 2>/dev/null
    or echo "  No active tokens — run 'aws-login' to authenticate"
end
```

---

## Phase 4 — Authenticate and Set Up EKS Kubeconfig

### 4.1 Login to SSO
Tell the user: "A browser window will open. Log in with your SSO credentials."
```bash
aws sso login --sso-session work-sso
```

### 4.2 Add all EKS clusters to kubeconfig
Run each command. The `--alias` flag sets the clean context name. The `--profile` flag
sets the correct AWS_PROFILE in the kubeconfig exec block automatically.

**Mumbai (ap-south-1) clusters:**
```bash
aws eks update-kubeconfig --region ap-south-1 --name non-prod-dso     --profile non-prod-dso     --alias non-prod-dso-mum
aws eks update-kubeconfig --region ap-south-1 --name prod-dso         --profile prod-dso         --alias prod-dso-mum
aws eks update-kubeconfig --region ap-south-1 --name eks-aps1         --profile non-prod-banking --alias non-prod-banking-mum
aws eks update-kubeconfig --region ap-south-1 --name eks-aps1         --profile prod-banking     --alias prod-banking-mum
aws eks update-kubeconfig --region ap-south-1 --name eks-aps1         --profile non-prod-non-banking --alias non-prod-non-banking-mum
aws eks update-kubeconfig --region ap-south-1 --name eks-aps1         --profile prod-non-banking --alias prod-non-banking-mum
aws eks update-kubeconfig --region ap-south-1 --name eks-aps1         --profile prod-analytics   --alias prod-analytics-mum
aws eks update-kubeconfig --region ap-south-1 --name prod-pci         --profile prod-pci         --alias prod-pci-mum
```

**Hyderabad (ap-south-2) clusters:**
```bash
aws eks update-kubeconfig --region ap-south-2 --name eks-aps2         --profile non-prod-banking     --alias non-prod-banking-hyd
aws eks update-kubeconfig --region ap-south-2 --name eks-aps2         --profile non-prod-non-banking --alias non-prod-non-banking-hyd
aws eks update-kubeconfig --region ap-south-2 --name eks-aps2         --profile prod-banking         --alias prod-banking-hyd
aws eks update-kubeconfig --region ap-south-2 --name eks-aps2         --profile prod-non-banking     --alias prod-non-banking-hyd
aws eks update-kubeconfig --region ap-south-2 --name prod-pci-dr      --profile prod-pci             --alias prod-pci-hyd
```

### 4.3 Fix kubeconfig AWS_PROFILE values
The `aws eks update-kubeconfig` command writes the profile name correctly when `--profile` is used.
Verify no old-style names snuck in:
```bash
grep -A1 "name: AWS_PROFILE" ~/.kube/config | grep "value:"
```
All values should match the profile names above (e.g. `non-prod-dso`, `prod-banking`). If any show
old-style names like `ne-xxx/ne-xxx-yyy`, fix them with sed.

---

## Phase 5 — Verify

Run these to confirm everything works:

```bash
# Profiles are all present
aws configure list-profiles | sort

# Contexts are all present
kubectl config get-contexts

# Test one profile end-to-end (will prompt browser if token expired)
aws sts get-caller-identity --profile non-prod-dso
```

If `aws sts get-caller-identity` succeeds, the setup is complete.

Tell the user:
- Run `aws-login` each morning to authenticate for the day
- Run `assume <profile>` to switch AWS profiles (e.g. `assume non-prod-dso`)
- Run `kubectl config use-context <ctx>` to switch clusters (e.g. `non-prod-dso-mum`)
- Run `aws-status` to check the current active profile and token state
