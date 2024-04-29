#!/bin/bash

# Function to monitor SSH login attempts
monitor_ssh_login() {
    journalctl -u ssh | grep "Accepted password for" | while read -r line; do
        echo "SSH login attempt: $line"
    done
}

# Function to monitor failed SSH authentication attempts
monitor_failted_ssh_login() {
    journalctl -u ssh | grep "Failed password for" | while read -r line; do
        echo "Failed SSH authentication attempt: $line"
    done
}

# Function to monitor failed local login attempts
monitor_failed_local_login() {
    journalctl | grep "Failed password for" | while read -r line; do
        echo "Failed local login attempt: $line"
    done
}

# Function to detect potential port scan attempts in UFW logs
detect_port_scan() {
    echo "Detecting potential port scan attempts..."

    # Store unique source IP addresses in an associative array
    declare -A seen_ips

    # Parse UFW logs and analyze connection patterns
    grep "UFW BLOCK" /var/log/ufw.log | while read -r line; do
        source_ip=$(echo "$line" | grep -oP 'SRC=\K[0-9.]+')
        connection_count=$(grep "SRC=$source_ip" /var/log/ufw.log | grep "UFW BLOCK" | wc -l)

        # Set threshold for number of connection attempts
        threshold=10

        # If connection count exceeds threshold and source IP is not seen before, print potential port scan attempt
        if [ "$connection_count" -gt "$threshold" ] && [ -z "${seen_ips[$source_ip]}" ]; then
            echo "Potential port scan attempt detected:"
            echo "Source IP: $source_ip"
            echo "Connection Count: $connection_count"
            echo

            # Mark source IP as seen
            seen_ips[$source_ip]=1
        fi
    done
    echo $seen_ips
}

# Main function
main() {
    monitor_ssh_login
    monitor_failted_ssh_login
    monitor_failed_local_login
    detect_port_scan
}

# Run the main function
main
