function kexf --description "Fuzzy pod picker then exec into it"
    set pod (kubectl get pods --no-headers | fzf --height=30% --prompt="Pod > " | awk '{print $1}')
    if test -n "$pod"
        set shell (if test (count $argv) -gt 0; echo $argv[1]; else; echo /bin/sh; end)
        kubectl exec -it $pod -- $shell
    end
end
