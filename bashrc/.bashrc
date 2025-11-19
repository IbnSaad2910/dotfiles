# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

export PATH="$HOME/.config/composer/vendor/bin:$PATH"
eval "$(~/.local/bin/mise activate bash)"
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
export PATH=$HOME/.dotnet/tools:$PATH

fastfetch
