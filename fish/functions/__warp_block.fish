# Adds a blank line after each command output, mimicking Warp's command block separation
function __warp_block --on-event fish_postexec
    printf '\n'
end
