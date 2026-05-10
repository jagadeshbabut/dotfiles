function klogf --description "Fuzzy pod picker then follow logs"
    set pod (kubectl get pods --no-headers | fzf --height=30% --prompt="Pod > " | awk '{print $1}')
    if test -n "$pod"
        kubectl logs -f $pod $argv
    end
end
