function ctx --description "Fuzzy k8s context switcher"
    set context (kubectx | fzf --height=20% --prompt="K8s Context > ")
    and kubectx $context
end
