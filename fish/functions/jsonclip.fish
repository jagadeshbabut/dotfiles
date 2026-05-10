function jsonclip --description "Pretty-print JSON from clipboard"
    pbpaste | jq '.'
end
