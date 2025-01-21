#!/bin/bash

# Color and emoji definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
CHECK_MARK="\xE2\x9C\x85"
CROSS_MARK="\xE2\x9D\x8C"
INFO_MARK="\xE2\x84\xB9\xEF\xB8\x8F"
WARN_MARK="\xE2\x9A\xA0\xEF\xB8\x8F"

# Helper function for status display
print_status() {
    if [ "$2" = "true" ] || [ "$2" = "on" ] || [ "$2" = "1" ]; then
        printf "${1}: ${GREEN}Enabled${NC} ${CHECK_MARK}\n"
    else
        printf "${1}: ${RED}Disabled${NC} ${CROSS_MARK}\n"
    fi
}

# Function to print section headers
print_header() {
    printf "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to disable macOS updates
disable_updates() {
    printf "Disabling macOS automatic updates...\n"
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -int 0
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdate -bool false
    sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -int 0
    printf "macOS automatic updates have been disabled.\n"
}

# Function to configure power settings
configure_power_settings() {
    printf "Configuring power management settings...\n"
    sudo pmset -a sleep 0
    sudo pmset -a powernap 0
    sudo pmset -a disksleep 0
    sudo pmset -a displaysleep 0
    sudo pmset -a womp 1  # Enable Wake on Network Access for remote management
    sudo pmset -a autopoweroff 0  # Disable auto power off
    sudo pmset -a standby 0  # Disable standby mode
    printf "Power management settings have been updated.\n"
}

# Function to configure remote access settings
configure_remote_access() {
    printf "Configuring remote access settings...\n"
    # Enable SSH using launchctl
    printf "Enabling SSH...\n"
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
    
    # Verify the settings
    printf "Remote Login status:\n"
    if sudo launchctl list | grep -q "com.openssh.sshd"; then
        printf "Remote Login: On\n"
    else
        printf "Remote Login: Off\n"
    fi
}

# Function to configure network settings
configure_network() {
    echo "Configuring network settings..."
    # Find Wi-Fi interface
    WIFI_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "en" | awk '{print $2}')
    
    if [ ! -z "$WIFI_INTERFACE" ]; then
        read -p "Do you want to disable Wi-Fi? (y/n): " wifi_response
        if [[ $wifi_response =~ ^[Yy]$ ]]; then
            sudo networksetup -setairportpower $WIFI_INTERFACE off
            echo "Wi-Fi ($WIFI_INTERFACE) has been disabled."
        fi
    else
        echo "No Wi-Fi interface found."
    fi
    
    read -p "Do you want to disable Bluetooth? (y/n): " bluetooth_response
    if [[ $bluetooth_response =~ ^[Yy]$ ]]; then
        sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0
        echo "Bluetooth has been disabled."
    fi
    echo "Network settings have been updated."
}

# Function to verify configurations
verify_configurations() {
    print_header "CONFIGURATION VERIFICATION"
    
    print_header "1. Software Update Settings"
    auto_check=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null || echo "1")
    auto_download=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload 2>/dev/null || echo "1")
    print_status "Automatic Check" "$([ "$auto_check" = "0" ] && echo true || echo false)"
    print_status "Automatic Download" "$([ "$auto_download" = "0" ] && echo true || echo false)"
    
    print_header "2. Power Management Settings"
    printf "${INFO_MARK} Current power settings:\n"
    pmset -g | sed 's/^/  /'
    
    print_header "3. Remote Access Settings"
    ssh_status=$(sudo launchctl list | grep -q "com.openssh.sshd" && echo "true" || echo "false")
    print_status "SSH Access" "$ssh_status"
    
    print_header "4. Network Settings"
    # Wi-Fi Status
    WIFI_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "en" | awk '{print $2}')
    if [ ! -z "$WIFI_INTERFACE" ]; then
        wifi_power=$(networksetup -getairportpower $WIFI_INTERFACE | grep "On" > /dev/null && echo "true" || echo "false")
        print_status "Wi-Fi ($WIFI_INTERFACE)" "$wifi_power"
    else
        printf "${INFO_MARK} No Wi-Fi interface found\n"
    fi
    
    # Bluetooth Status - Fixed version
    bluetooth_status=$(system_profiler SPBluetoothDataType 2>/dev/null | grep -q "State: On" && echo "true" || echo "false")
    print_status "Bluetooth" "$bluetooth_status"
    
    # Screen Sharing Status
    screen_sharing=$(launchctl list | grep -q "com.apple.screensharing" && echo "true" || echo "false")
    print_status "Screen Sharing Service" "$screen_sharing"
    
    printf "\n${YELLOW}${WARN_MARK} IMPORTANT: Manual Configuration Required${NC}\n"
    printf "${INFO_MARK} Please configure Screen Sharing:\n"
    printf "  1. Go to System Settings > Sharing\n"
    printf "  2. Enable Screen Sharing\n"
    
    printf "\n${YELLOW}${WARN_MARK} Configuration Review${NC}\n"
    read -p "Do all settings look correct? (y/n): " verify_response
    if [[ ! $verify_response =~ ^[Yy]$ ]]; then
        printf "${RED}${CROSS_MARK} Please review the script and run again if needed.${NC}\n"
        exit 1
    fi
}

# Main script execution
printf "${BLUE}=== Starting Datacenter Mac Configuration ===${NC}\n"

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then 
    printf "${RED}${CROSS_MARK} Please run this script with sudo${NC}\n"
    exit 1
fi

disable_updates
configure_power_settings
configure_remote_access

# Ask for network configuration
read -p "Do you want to configure network settings (Wi-Fi/Bluetooth)? (y/n): " network_response
if [[ $network_response =~ ^[Yy]$ ]]; then
    configure_network
fi

printf "\nRunning verification checks...\n"
verify_configurations

printf "Configuration completed successfully!\n"
printf "All settings have been verified and confirmed.\n"
