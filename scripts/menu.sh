#!/bin/bash

# Load menu functions
source menu_functions.sh

# Define the menu options and their corresponding commands
declare -A options
options=(
    ["Reload bashrc"]="source ~/.bashrc; source_bashrc_with_message"
    ["LXC Updater"]='bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/update-lxcs.sh)"'
    ["List all LXC containers"]="pct list"
    ["List All Virtual Machines"]="qm list"
    ["List Available Templates"]="pveam available"
    ["Show Proxmox Version"]="pveversion"
    ["Update custom bashrc"]="source ~/.bashrc; custom_bashrc_update"
)

# Array of option labels, including the Quit option
option_labels=("LXC Updater"
               "List all LXC containers"
               "List All Virtual Machines"
               "List Available Templates"
               "Show Proxmox Version"
               "Update custom bashrc"
               "Reload bashrc"
               "Quit")


# Call the main menu function
main_menu
