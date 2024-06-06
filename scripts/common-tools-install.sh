#!/usr/bin/env bash

echo "Updating package lists..."
apt-get update
echo "Installing fzf..."
apt-get install fzf

echo "Downloading .bashrc_custom from the remote location..."
curl -sSfL https://github.com/dreed47/linux-tools/raw/main/scripts/.bashrc_custom -o ~/.bashrc_custom

# Check if the bashrc_custom call already exists in ~/.bashrc
if ! grep -qxF "source ~/.bashrc_custom" ~/.bashrc; then
  echo "Adding source ~/.bashrc_custom to ~/.bashrc..."
  echo "source ~/.bashrc_custom" >> ~/.bashrc
else
  echo "~/.bashrc_custom is already sourced in ~/.bashrc"
fi

echo "Reloading ~/.bashrc..."
source ~/.bashrc

echo " "
echo "Script execution completed."
