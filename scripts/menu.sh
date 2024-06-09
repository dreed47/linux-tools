#!/bin/bash

# Load menu functions
source menu_functions.sh

# Define the menu options and their corresponding commands
declare -A options
options=(
    ["Reload bashrc"]="source ~/.bashrc; source_bashrc_with_message"
    ["LXC Updater"]='bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/update-lxcs.sh)"'
    ["List All Virtual Machines"]="qm list"
    ["Update custom bashrc"]="source ~/.bashrc; custom_bashrc_update"
)

# Array of option labels, including the Quit option
option_labels=("Reload bashrc"
               "LXC Updater"
               "List All Virtual Machines"
               "Update custom bashrc"
               "Quit")


# Call the main menu function
main_menu
