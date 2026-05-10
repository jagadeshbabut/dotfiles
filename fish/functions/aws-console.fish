function aws-console --description "Fuzzy pick a profile and open its AWS console in browser"
    set profile (aws configure list-profiles | fzf --height=20% --prompt="AWS Console > ")
    if test -n "$profile"
        source /opt/homebrew/bin/assume.fish $profile --console
    end
end
