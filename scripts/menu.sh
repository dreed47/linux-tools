#!/bin/bash
#
# dreed47/linux-tools - Proxmox Menu
# https://github.com/dreed47/linux-tools
#
# Run directly:
#   bash -c "$(wget -qLO - https://github.com/dreed47/linux-tools/raw/main/scripts/menu.sh)"

# Define the menu options and their corresponding commands
declare -A options
options=(
    ["LXC Updater"]='bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/update-lxcs.sh)"'
    ["List all LXC containers"]="pct list"
    ["List All Virtual Machines"]="qm list"
    ["List Available Templates"]="pveam available"
    ["Show Proxmox Version"]="pveversion"
    ["Proxmox Node Tools"]='bash -c "$(wget -qLO - https://github.com/dreed47/linux-tools/raw/main/scripts/common-tools-install.sh)"'
    ["Proxmox Debian Container Tools"]='bash -c "$(wget -qLO - https://github.com/dreed47/linux-tools/raw/main/scripts/common-container-tools-install.sh)"'
    ["Upgrade Debian 12 to 13"]='bash -c "$(wget -qLO - https://github.com/dreed47/linux-tools/raw/main/scripts/upgrade-debian-12-to-13.sh)"'
    ["Proxmox Node Space Cleanup"]='bash -c "$(wget -qLO - https://github.com/dreed47/linux-tools/raw/main/scripts/proxmox-node-cleanup.sh)"'
    ["Update custom bashrc"]="source ~/.bashrc; custom_bashrc_update"
    ["Reload bashrc"]="source ~/.bashrc; source_bashrc_with_message"
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

# Function to display the menu
display_menu() {
    clear
    echo "Select an option (use arrow keys to navigate and Enter to select):"
    for i in "${!option_labels[@]}"; do
        if [[ $i -eq $1 ]]; then
            echo -e "\e[1;32m> ${option_labels[$i]}\e[0m"
        else
            echo "  ${option_labels[$i]}"
        fi
    done
}

# Function to handle menu selection
handle_selection() {
    if [[ $1 -lt ${#option_labels[@]}-1 ]]; then
        echo "Executing: ${option_labels[$1]}"
        eval "${options[${option_labels[$1]}]}"
        echo -e "\nPress any key to exit..."
        read -n 1 -s
    else
        clear
        echo "Exiting menu..."
    fi
}

# Main menu loop
main_menu() {
    local current_selection=0
    while true; do
        display_menu $current_selection

        read -rsn1 input
        if [[ $input == $'\x1b' ]]; then
            read -rsn2 -t 0.1 input
            if [[ $input == "[A" ]]; then
                # Up arrow key
                ((current_selection--))
                if [[ $current_selection -lt 0 ]]; then
                    current_selection=$((${#option_labels[@]} - 1))
                fi
            elif [[ $input == "[B" ]]; then
                # Down arrow key
                ((current_selection++))
                if [[ $current_selection -ge ${#option_labels[@]} ]]; then
                    current_selection=0
                fi
            fi
        elif [[ $input == "" ]]; then
            handle_selection $current_selection
            [[ ${option_labels[$current_selection]} == "Quit" ]] && break
        fi
    done
}

# Call the main menu function
main_menu
