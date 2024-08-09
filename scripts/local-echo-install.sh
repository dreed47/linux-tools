#!/usr/bin/env bash
# Define colors for status messages
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0) # Reset color

echo "${YELLOW}Updating package lists and perform upgrades...${RESET}"
apt-get update && sudo apt-get upgrade

echo "${YELLOW}Installing tools...${RESET}"
apt-get install -y --no-install-recommends  \
  git \
  python3-venv \
  libopenblas-dev \
  python3-spidev \
  python3-gpiozero \
  fzf

cd /opt
echo "..."
echo "${YELLOW}Cloning repos...${RESET}"
git clone https://github.com/rhasspy/wyoming-satellite.git
git clone https://github.com/rhasspy/wyoming-openwakeword.git

echo "..."
echo "${YELLOW}Install speaker drivers...${RESET}"
cd /opt/wyoming-satellite/  
bash etc/install-respeaker-drivers.sh  

echo " "
echo "${GREEN}Script execution completed.${RESET}"
