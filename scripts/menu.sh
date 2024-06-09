#!/bin/bash

# Load menu functions
source menu_functions.sh

# Define the menu options and their corresponding commands
declare -A options
options=(
    ["reload bash"]="source ~/.bashrc; source_bashrc_with_message"
    ["LXC Updater"]='bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/update-lxcs.sh)"'
    ["update custom bash"]="source ~/.bashrc; custom_bashrc_update"
)

# Array of option labels, including the Quit option
option_labels=("reload bash" "LXC Updater" "update custom bash" "Quit")

# Call the main menu function
main_menu
