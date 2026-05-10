set -g -x PATH /usr/local/bin:/opt/homebrew/bin /opt/homebrew/sbin $PATH

# Aliases
source ~/.config/fish/aliases.fish

# Granted (AWS SSO profile switcher)
export GRANTED_ALIAS_CONFIGURED="true"
alias assume="source /opt/homebrew/bin/assume.fish"

# Kubectl completions
kubectl completion fish | source

# Starship prompt
starship init fish | source

# Welcome banner
figlet -c -W -f banner3-D JAGA

# Machine-local overrides (not tracked in git)
if test -f ~/.config/fish/local.fish
    source ~/.config/fish/local.fish
end
