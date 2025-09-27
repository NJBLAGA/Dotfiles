HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

bindkey -v
zstyle :compinstall filename '/home/njblaga/.zshrc' 

export BROWSER=/usr/bin/zen

# shells
alias to_bash='exec bash'
alias to_zsh='exec zsh'
alias check_shell='if [ -n "$BASH_VERSION" ]; then echo "You are running bash, version $BASH_VERSION"; else echo "You are NOT running bash"; fi'
# timeshift
alias timeshift='pkexec env DISPLAY=$DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR WAYLAND_DISPLAY=$WAYLAND_DISPLAY timeshift-gtk
'
# lg
alias ls="colorls"
#vpn - Australia
alias aus="nordvpn connect Australia"
#vpn - United_States
alias usa="nordvpn connect United_States"
# cdi - zoxide\
cdi-widget() {
  BUFFER="cdi"
  zle accept-line
}

# Create the widget
zle -N cdi-widget

# Bind Alt + d to the widget
bindkey "^[d" cdi-widget

# open files
alias open='open_func'

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

start_tmux_njblaga() {
  if tmux has-session -t njblaga 2>/dev/null; then
    tmux attach -t njblaga
  else
    tmux new -s njblaga
  fi
}
if [[ -z "$TMUX" ]]; then
  start_tmux_njblaga
fi

# search files
bindkey -s '\e ' 'fzf_preview_bat\n'

fzf_preview_bat() {
  fzf --multi --preview "bat --color=always --style=numbers --line-range=:500 {}" | \
    xargs -r nvim -p
}

# search history
bindkey -s '^[h' 'fzf_history_confirm\n'

fzf_history_confirm() {
  # Get command from history, show with fzf
  local cmd
  cmd=$(history | fzf --tac --no-sort --reverse --preview-window=down:3:wrap --preview "echo {}")

  # Exit if no selection (ESC)
  [[ -z "$cmd" ]] && return

  # 'history' output includes line numbers, so strip them
  # Example: " 1039  ls -la"
  local clean_cmd
  clean_cmd=$(echo "$cmd" | sed -E 's/^[[:space:]]*[0-9]+\s+//')

  # Confirmation prompt (read single char, no enter)
  echo -n "Do you wish to use this command again? (y/n): "
  read -k 1 confirm
  echo

  if [[ "$confirm" == "y" ]]; then
    eval "$clean_cmd"
  else
    echo "Command cancelled."
  fi
}

# Default Apps
export EDITOR="nvim"
export TERMINAL="ghostty"

# -- SETTING THE STARSHIP PROMPT --
eval "$(starship init zsh)"

#fzf
source <(fzf --zsh)

#zoxide
eval "$(zoxide init --cmd cd zsh)"

export PATH="$HOME/.local/share/gem/ruby/3.4.0/bin:$PATH"

# Add pipx binaries to PATH temporarily
export PATH="$HOME/.local/bin:$PATH"

# Created by `pipx` on 2025-08-23 23:32:13
export PATH="$PATH:/home/njblaga/.local/bin"
