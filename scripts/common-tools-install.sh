#!/usr/bin/env bash

apt-get update
apt-get install fzf

# Download .bashrc_custom from the remote location
curl -sSfL https://github.com/dreed47/linux-tools/raw/main/scripts/.bashrc_custom -o ~/.bashrc_custom

# Check if the bashrc_custom call already exists in ~/.bashrc
if ! grep -qxF "source ~/.bashrc_custom" ~/.bashrc; then
  echo "source ~/.bashrc_custom" >> ~/.bashrc
fi
