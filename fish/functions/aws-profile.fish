function aws-profile --description "Fuzzy AWS profile switcher via granted"
    set profile (aws configure list-profiles | fzf --height=20% --prompt="AWS Profile > ")
    if test -n "$profile"
        source /opt/homebrew/bin/assume.fish $profile
        echo "Switched to: $profile"
        aws sts get-caller-identity --output table 2>/dev/null
    end
end
