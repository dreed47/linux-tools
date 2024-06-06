#!/usr/bin/env bash

apt-get update
apt-get install fzf

awk 'BEGIN { found=0 } /^fh\(\) \{$/ { found=1; exit } END { if (!found) { system("cat << EOF >> ~/.bashrc\n\nfh() {\n  local cmd=$(history | fzf | sed \"s/^[ ]*[0-9]*[ ]*//\")\n  if [ -n \"$cmd\" ]; then\n    eval \"$cmd\"\n  fi\n}\n\nEOF") } }' ~/.bashrc
