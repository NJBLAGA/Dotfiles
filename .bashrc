# ~/.bashrc

# History settings
HISTFILE=~/.histfile
HISTSIZE=10000
HISTFILESIZE=10000
shopt -s histappend # Append to history, don't overwrite

# Enable vi mode for command line editing
set -o vi

# Aliases
alias to_bash='exec bash'
alias to_zsh='exec zsh'
alias new_tmux='tmux new -s'
# ls
alias ls="colorls"
#vpn - Australia
alias aus="nordvpn connect Australia"
#vpn - United_States
alias usa="nordvpn connect United_States"
# cd - zoxide
cdi_run() {
  # Clear the current command line, if any
  # and run cdi
  # Note: this won't insert 'cdi' but will execute it directly
  cdi
}

# Bind Alt+d to run cdi_run function
bind -x '"\ed":cdi_run'

alias check_shell='if [ -n "$BASH_VERSION" ]; then echo "You are running bash, version $BASH_VERSION"; else echo "You are NOT running bash"; fi'

# Function to open files/folders with dolphin
open_func() {
  if [[ $# -eq 0 ]]; then
    dolphin .
  else
    for target in "$@"; do
      if [[ -e $target ]]; then
        if [[ -d $target ]]; then
          dolphin "$target"
        else
          dolphin --select "$target"
        fi
      else
        echo "open: '$target' does not exist"
      fi
    done
  fi
}

alias open='open_func'

# fzf preview function - open selected files in nvim tabs
fzf_preview_bat() {
  fzf --multi --preview "bat --color=always --style=numbers --line-range=:500 {}" |
    xargs -r nvim -p
}

# Search history with fzf and confirmation prompt
fzf_history_confirm() {
  local cmd
  cmd=$(history | fzf --tac --no-sort --reverse --preview-window=down:3:wrap --preview "echo {}")
  [[ -z "$cmd" ]] && return
  local clean_cmd
  clean_cmd=$(echo "$cmd" | sed -E 's/^[[:space:]]*[0-9]+\s+//')
  echo -n "Do you wish to use this command again? (y/n): "
  read -n 1 confirm
  echo
  if [[ "$confirm" == "y" ]]; then
    eval "$clean_cmd"
  else
    echo "Command cancelled."
  fi
}

# Default apps
export EDITOR="nvim"
export TERMINAL="ghosty"

# Only run the following if the shell is bash
if [ -n "$BASH_VERSION" ]; then
  # Append to history, don't overwrite
  shopt -s histappend

  # Bind Alt+Space to fzf_preview_bat
  bind '"\e ": "fzf_preview_bat\n"'

  # Bind Alt+h to fzf_history_confirm
  bind '"\eh": "fzf_history_confirm\n"'

  # Initialize starship prompt for bash
  eval "$(starship init bash)"

  # zoxide
  eval "$(zoxide init --cmd cd bash)"

  # Source fzf bash keybindings if present
  [ -f ~/.fzf.bash ] && source ~/.fzf.bash
fi

# Add Ruby gem path to PATH
export PATH="$HOME/.local/share/gem/ruby/3.4.0/bin:$PATH"
