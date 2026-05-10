function b64e --description "Base64 encode a string"
    echo -n $argv[1] | base64
end
