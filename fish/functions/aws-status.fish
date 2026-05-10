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
