function watchurl --description "Poll a URL and print HTTP status every N seconds"
    if test (count $argv) -eq 0
        echo "Usage: watchurl <url> [interval_seconds]"
        return 1
    end
    set url $argv[1]
    set interval (if test (count $argv) -ge 2; echo $argv[2]; else; echo 5; end)
    watch -n $interval "curl -s -o /dev/null -w 'HTTP %{http_code} | %{time_total}s' $url"
end
