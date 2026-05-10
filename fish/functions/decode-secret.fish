function decode-secret --description "Decode all fields of a k8s secret"
    if test (count $argv) -eq 0
        echo "Usage: decode-secret <secret-name> [namespace]"
        return 1
    end
    set ns_flag
    if test (count $argv) -ge 2
        set ns_flag -n $argv[2]
    end
    kubectl get secret $argv[1] $ns_flag -o json \
        | jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"'
end
