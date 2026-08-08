#!/bin/bash

# Load menu functions
source menu_functions.sh

# Define the menu options and their corresponding commands
declare -A options
options=(
    ["Reload bashrc"]="source ~/.bashrc; source_bashrc_with_message"
    ["Update custom bashrc"]="source ~/.bashrc; custom_bashrc_update"
    ["LXC Updater"]='bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/update-lxcs.sh)"'
    ["List all LXC containers"]="pct list"
    ["List All Virtual Machines"]="qm list"
    ["List Available Templates"]="pveam available"
    ["Show Proxmox Version"]="pveversion"
    ["Proxmox Node Tools"]='bash -c "$(wget -qLO - https://github.com/dreed47/linux-tools/raw/main/scripts/common-tools-install.sh)"'
    ["Proxmox Debian Container Tools"]='bash -c "$(wget -qLO - https://github.com/dreed47/linux-tools/raw/main/scripts/common-container-tools-install.sh)"'
    ["Upgrade Debian 12 to 13"]='bash -c "$(wget -qLO - https://github.com/dreed47/linux-tools/raw/main/scripts/upgrade-debian-12-to-13.sh)"'
    ["Proxmox Node Space Cleanup"]='bash -c "$(wget -qLO - https://github.com/dreed47/linux-tools/raw/main/scripts/proxmox-node-cleanup.sh)"'
)

# Array of option labels, including the Quit option
option_labels=("LXC Updater"
               "List all LXC containers"
               "List All Virtual Machines"
               "List Available Templates"
               "Show Proxmox Version"
               "Proxmox Node Tools"
               "Proxmox Debian Container Tools"
               "Upgrade Debian 12 to 13"
               "Proxmox Node Space Cleanup"
               "Update custom bashrc"
               "Reload bashrc"
               "Quit")

# Call the main menu function
main_menu
