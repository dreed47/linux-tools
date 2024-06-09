#!/bin/bash

# Load menu functions
source menu_functions.sh

# Define the menu options and their corresponding commands
declare -A options
options=(
    ["reload bash"]="source ~/.bashrc; source_bashrc_with_message"
    ["update custom bash"]="source ~/.bashrc; custom_bashrc_update"
)

# Array of option labels, including the Quit option
option_labels=("reload bash" "update custom bash" "Quit")

# Call the main menu function
main_menu
