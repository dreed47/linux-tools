#!/usr/bin/env bash
# Define colors for status messages
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0) # Reset color

echo "${YELLOW}Updating package lists...${RESET}"
apt-get update
echo "${YELLOW}Installing fzf...${RESET}"
apt-get install fzf

echo "${YELLOW}Removing old .bashrc_custom if it exists...${RESET}"
rm -rvf ~/.bashrc_custom
echo "${YELLOW}Downloading .bashrc_custom from the remote location...${RESET}"
curl -sSfL https://github.com/dreed47/linux-tools/raw/main/scripts/.bashrc_custom -o ~/.bashrc_custom

# Check if the bashrc_custom call already exists in ~/.bashrc
if ! grep -qxF "source ~/.bashrc_custom" ~/.bashrc; then
  echo "${YELLOW}Adding source ~/.bashrc_custom to ~/.bashrc...${RESET}"
  echo "source ~/.bashrc_custom" >> ~/.bashrc
else
  echo "${GREEN}~/.bashrc_custom is already sourced in ~/.bashrc${RESET}"
fi

echo "${YELLOW}Reloading ~/.bashrc...${RESET}"
source ~/.bashrc

echo " "
echo "${GREEN}Script execution completed.${RESET}"
