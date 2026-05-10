# Migrate fish_key_bindings from universal (pre-4.3) to global scope.
# Delete this file and configure key bindings in config.fish if needed.

# Erase the universal variable so fish 4.3+ takes over
set --erase --universal fish_key_bindings
