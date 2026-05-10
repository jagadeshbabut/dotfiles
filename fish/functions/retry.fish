function retry --description "Retry a command N times with a delay between attempts"
    set max $argv[1]
    set delay $argv[2]
    set cmd $argv[3..]
    set count 0
    while not $cmd
        set count (math $count + 1)
        if test $count -ge $max
            echo "Failed after $max attempts"
            return 1
        end
        echo "Attempt $count/$max failed. Retrying in {$delay}s..."
        sleep $delay
    end
end
