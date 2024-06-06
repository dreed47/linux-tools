#!/usr/bin/env bash

apt-get update
apt-get install fzf

# Define the function and aliases in variables
fh_function='fh() {
  local cmd=$(history | fzf | sed "s/^[ ]*[0-9]*[ ]*//")
  if [ -n "$cmd" ]; then
    eval "$cmd"
  fi
}'

# Define the content of .bashrc_custom
custom_content="# .bashrc_custom
# Custom functions and aliases

$fh_function

# Aliases
alias fcd='cd \$(find * -type d | fzf)'
alias vf='vim \$(fzf)'
alias fhf='history | fzf'
export LS_OPTIONS='--color=auto'
eval '$(dircolors)'
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -la'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

"


# Write or overwrite .bashrc_custom
echo "$custom_content" > ~/.bashrc_custom

# Check if the function already exists in ~/.bashrc
if ! grep -qxF "source ~/.bashrc_custom" ~/.bashrc; then
  echo "source ~/.bashrc_custom" >> ~/.bashrc
fi
