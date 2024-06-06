#!/usr/bin/env bash

apt-get update
apt-get install fzf

grep -qF 'fh() {' ~/.bashrc || cat << 'EOF' >> ~/.bashrc

fh() {
  local cmd=\$(history | fzf | sed "s/^[ ]*[0-9]*[ ]*//")
  if [ -n "\$cmd" ]; then
    eval "\$cmd"
  fi
}

EOF
