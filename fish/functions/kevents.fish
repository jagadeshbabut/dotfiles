function kevents --description "Show k8s events sorted by time"
    kubectl get events --sort-by='.lastTimestamp' $argv
end
