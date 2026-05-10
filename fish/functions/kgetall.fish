function kgetall --description "Get all resource types in a namespace"
    set ns (if test (count $argv) -gt 0; echo $argv[1]; else; kubens -c; end)
    echo "── Namespace: $ns ──"
    for resource in pods deployments services ingresses configmaps secrets jobs cronjobs statefulsets daemonsets
        echo "\n── $resource ──"
        kubectl get $resource -n $ns 2>/dev/null
    end
end
