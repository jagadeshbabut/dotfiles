function y2j --description "Convert YAML to JSON"
    yq -o=json $argv
end
