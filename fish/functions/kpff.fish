function kpff --description "Fuzzy port-forward to a pod or service"
    set target (kubectl get svc,pods --no-headers | fzf --height=30% --prompt="Port-Forward > " | awk '{print $1}')
    if test -n "$target"
        set remote_port (if test (count $argv) -ge 1; echo $argv[1]; else; echo 80; end)
        set local_port (if test (count $argv) -ge 2; echo $argv[2]; else; echo 8080; end)
        echo "Forwarding $local_port:$remote_port to $target"
        kubectl port-forward $target $local_port:$remote_port
    end
end
