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

Write the following exactly to `~/.aws/config` (create `~/.aws/` directory if needed).
Do NOT overwrite if the file already contains `[sso-session slice-sso]` — ask the user first.

```ini
[sso-session slice-sso]
#
sso_start_url           = https://d-9f67050f34.awsapps.com/start/
sso_region              = ap-south-1
sso_registration_scopes = sso:account:access

[default]
sso_session    = slice-sso
sso_start_url  = https://d-9f67050f34.awsapps.com/start/
sso_region     = ap-south-1

[profile audit-account]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 774305599951
granted_sso_role_name      = ne-audit-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile audit-account

[profile log-archive]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 982534379409
granted_sso_role_name      = ne-log-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile log-archive

[profile terraform-account-factory]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 539247487200
granted_sso_role_name      = ne-tf-account-factory-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile terraform-account-factory

[profile backup]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 869935075933
granted_sso_role_name      = ne-backup-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile backup

[profile it-applications]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 039612850790
granted_sso_role_name      = ne-it-applications-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile it-applications

[profile non-prod-analytics]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 221082179410
granted_sso_role_name      = ne-non-prod-analytics-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile non-prod-analytics

[profile non-prod-banking]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 575108958249
granted_sso_role_name      = ne-non-prod-banking-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile non-prod-banking

[profile non-prod-dso]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 288761739962
granted_sso_role_name      = ne-non-prod-dso-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile non-prod-dso

[profile non-prod-networking]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 872515258109
granted_sso_role_name      = ne-non-prod-networking-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile non-prod-networking

[profile non-prod-non-banking]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 879381256642
granted_sso_role_name      = ne-non-prod-non-bank-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile non-prod-non-banking

[profile prod-analytics]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 820242914423
granted_sso_role_name      = ne-prod-analytics-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile prod-analytics

[profile prod-banking]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 762233762623
granted_sso_role_name      = ne-prod-banking-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile prod-banking

[profile prod-dso]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 122610482619
granted_sso_role_name      = ne-prod-dso-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile prod-dso

[profile prod-networking]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 182399705178
granted_sso_role_name      = ne-prod-networking-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile prod-networking

[profile prod-non-banking]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 490004614555
granted_sso_role_name      = ne-prod-non-banking-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile prod-non-banking

[profile prod-pci]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 905990871300
granted_sso_role_name      = ne-prod-pci-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile prod-pci

[profile prod-vendor]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 961341521203
granted_sso_role_name      = ne-prod-vendor-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile prod-vendor

[profile shared-services]
granted_sso_start_url      = `https://d-9f67050f34.awsapps.com/start/#`
granted_sso_region         = ap-south-1
granted_sso_account_id     = 145628349555
granted_sso_role_name      = nesfb-shared-services-admin-sso
common_fate_generated_from = aws-sso
credential_process         = granted credential-process --profile shared-services
```

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
function aws-login --description "Morning AWS SSO login - authenticates all profiles via slice-sso"
    set -l sso_session "slice-sso"
    set -l sso_url "https://d-9f67050f34.awsapps.com/start/"

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
aws sso login --sso-session slice-sso
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
