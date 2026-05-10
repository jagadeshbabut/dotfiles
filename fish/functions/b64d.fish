function b64d --description "Base64 decode a string"
    echo -n $argv[1] | base64 -d
    echo
end
