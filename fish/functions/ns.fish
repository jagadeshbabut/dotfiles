function ns --description "Fuzzy k8s namespace switcher"
    set namespace (kubens | fzf --height=20% --prompt="Namespace > ")
    and kubens $namespace
end
