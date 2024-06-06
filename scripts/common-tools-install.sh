#!/usr/bin/env bash

apt-get update
apt-get install fzf

# Define the function in a variable
fh_function='fh() {
  local cmd=$(history | fzf | sed "s/^[ ]*[0-9]*[ ]*//")
  if [ -n "$cmd" ]; then
    eval "$cmd"
  fi
}'

# Check if the function already exists in ~/.bashrc
grep -qxF "$fh_function" ~/.bashrc || echo "$fh_function" >> ~/.bashrc
