#!/usr/bin/env bash
# Define colors for status messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "${YELLOW}Updating package lists...${NC}"
apt-get update
echo "${YELLOW}Installing fzf...${NC}"
apt-get install fzf

echo "${YELLOW}Downloading .bashrc_custom from the remote location...${NC}"
curl -sSfL https://github.com/dreed47/linux-tools/raw/main/scripts/.bashrc_custom -o ~/.bashrc_custom

# Check if the bashrc_custom call already exists in ~/.bashrc
if ! grep -qxF "source ~/.bashrc_custom" ~/.bashrc; then
  echo "${YELLOW}Adding source ~/.bashrc_custom to ~/.bashrc...${NC}"
  echo "source ~/.bashrc_custom" >> ~/.bashrc
else
  echo "${YELLOW}~/.bashrc_custom is already sourced in ~/.bashrc${NC}"
fi

echo "${YELLOW}Reloading ~/.bashrc...${NC}"
source ~/.bashrc

echo " "
echo "${YELLOW}Script execution completed.${NC}"
