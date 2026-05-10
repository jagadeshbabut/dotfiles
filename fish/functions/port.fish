function port --description "Show what is running on a port"
    if test (count $argv) -eq 0
        echo "Usage: port <port_number>"
        return 1
    end
    lsof -i :$argv[1] -P -n
end
