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

# Check if the function already exists in ~/.bashrc
if ! grep -qxF "fh() {" ~/.bashrc; then
  echo "$fh_function" >> ~/.bashrc
fi

# Define the aliases
aliases='
alias fcd="cd \$(find * -type d | fzf)"
alias vf="vim \$(fzf)"
alias fhf="history | fzf"'

# Check if the aliases already exist in ~/.bashrc
if ! grep -qxF "alias fcd=" ~/.bashrc || ! grep -qxF "alias vf=" ~/.bashrc || ! grep -qxF "alias fhf=" ~/.bashrc; then
  echo "$aliases" >> ~/.bashrc
fi
