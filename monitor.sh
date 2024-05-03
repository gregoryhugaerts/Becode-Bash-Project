#!/bin/bash

monitor_successful_ssh_login() {
    # Grep for accepted password and parse out relevant information for display
    journalctl -u ssh $time_filter $message_level_option | grep "Accepted password for" | while read -r line; do
        login_time=$(echo "$line" | awk '{print $1,$3}')
        username=$(echo "$line" | awk '{print $9}')
        echo "$login_time $username"
    done
}

monitor_failed_ssh_login() {
    # Use awk for pattern matching and printing within the journalctl command
    journalctl -u ssh $time_filter $message_level_option | grep 'Failed password for' | awk '{print "Failed SSH authentication attempt: ", $0}'
}

monitor_failed_local_login() {
    # Grep for accepted password and parse out relevant information for display
    journalctl $time_filter $message_level_option | grep "Failed password for" | grep -v ssh | while read -r line; do
        login_time=$(echo "$line" | awk '{print $1,$3}')
        username=$(echo "$line" | awk '{print $6}')
        echo "$login_time $username"
    done
}

# Function to detect potential port scan attempts in UFW logs
detect_port_scan() {
    # Store unique source IP addresses in a file
    seen_ips_file="/tmp/seen_ips.txt"

    # Create an empty file if it doesn't exist
    touch "$seen_ips_file"

    # Parse UFW logs and analyze connection patterns
    journalctl $time_filter $message_level_option | grep "UFW BLOCK" | while read -r line; do
        source_ip=$(echo "$line" | grep -oP 'SRC=\K[0-9.]+')

        # Check if the source IP has been seen before
        if grep -q "$source_ip" "$seen_ips_file"; then
            continue
        fi

        # Count the number of connection attempts from the source IP
        connection_count=$(journalctl $time_filter $message_level_option | grep "SRC=$source_ip" | grep "UFW BLOCK" | wc -l)

        # Set threshold for number of connection attempts
        threshold=10

        # If connection count exceeds threshold, print potential port scan attempt
        if [ "$connection_count" -gt "$threshold" ]; then
            echo "Potential port scan attempt detected:"
            echo "Source IP: $source_ip"
            echo "Connection Count: $connection_count"
            echo

            # Mark source IP as seen
            echo "$source_ip" >>"$seen_ips_file"
        fi
    done
    rm "$seen_ips_file"
}

# display sofware installs/removals with apt package manager
software_updates() {
    grep -E 'remove|install' /var/log/apt/history.log
}

# display hardware events from systemd-udevd
hardware_events() {
    journalctl -u systemd-udevd | cat
}

#display boot messages
boot_messages() {
    journalctl -b | grep 'boot' | cat 
}

# Main function
main() {
    echo "Succesful SSH attempts:"
    echo "------------------------"
    monitor_successful_ssh_login
    echo
    echo "Failed SSH attempts:"
    echo "------------------------"
    monitor_failed_ssh_login
    echo
    echo "Failed local login attempts:"
    echo "------------------------"
    monitor_failed_local_login
    echo
    echo "Detecting potential port scan attempts"
    echo "------------------------"
    #detect_port_scan
    echo
    echo "Software Changes"
    echo "----------------"
    software_updates
    echo
    echo "Hardware Events"
    echo "----------------"
    hardware_events
    echo
    echo "Boot Messages"
    echo "----------------"   
    boot_messages
}

# Parse command line options
while getopts ":t:l:" opt; do
    case $opt in
        t)
            time_filter="--since $OPTARG"
            ;;
        l)
            message_level_option="-p $OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done

# Run the main function
main
