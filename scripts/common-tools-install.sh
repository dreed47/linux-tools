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
if ! grep -qxF "source ~/.bashrc_custom" ~/.bashrc; then
  echo "source ~/.bashrc_custom" >> ~/.bashrc
fi

# Write or overwrite .bashrc_custom
cat > ~/.bashrc_custom << EOF
# .bashrc_custom
# Custom functions and aliases

$fh_function

# Aliases
alias fcd='cd \$(find * -type d | fzf)'
alias vf='vim \$(fzf)'
alias fhf='history | fzf'

# LS_COLORS
export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=
