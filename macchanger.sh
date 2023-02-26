#!/bin/bash

# Usage: sudo ./macchanger.sh <interface> [options]

# Check if running as root
if [[ $(id -u) -ne 0 ]]; then
   echo "This script must be run as root. Exiting..." >&2
   exit 1
fi

# Check if the required command is installed
if ! command -v macchanger &> /dev/null; then
    echo "macchanger command not found. Please install it first. Exiting..." >&2
    exit 1
fi

# Get the command line arguments
INTERFACE="$1"
shift
OPTIONS="$@"

# Store the original MAC address of the interface
ORIGINAL_MAC=$(macchanger -s $INTERFACE | grep "Permanent MAC:" | awk '{print $4}')

# Generate a random MAC address if none is specified
if [[ -z "$OPTIONS" ]]; then
    NEW_MAC=$(macchanger -r $INTERFACE | grep "New MAC:" | awk '{print $3}')
else
    # Use the specified MAC address
    NEW_MAC=$(echo "$OPTIONS" | grep -Eoi '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$')
    if [[ -z "$NEW_MAC" ]]; then
        echo "Invalid MAC address format. Please specify a valid MAC address. Exiting..." >&2
        exit 1
    fi
    # Check if the specified MAC address is different from the original one
    if [[ "$NEW_MAC" == "$ORIGINAL_MAC" ]]; then
        echo "The specified MAC address is the same as the original one. Exiting..." >&2
        exit 1
    fi
    # Change the MAC address to the specified one
    macchanger -m $NEW_MAC $INTERFACE
fi

# Disable the network interface
ifconfig $INTERFACE down

# Change the MAC address
macchanger $OPTIONS $INTERFACE

# Enable the network interface
ifconfig $INTERFACE up

# Get the new MAC address
NEW_MAC=$(macchanger -s $INTERFACE | grep "Current MAC:" | awk '{print $3}')

# Print the results
echo "Interface: $INTERFACE"
echo "Original MAC address: $ORIGINAL_MAC"
echo "New MAC address: $NEW_MAC"
