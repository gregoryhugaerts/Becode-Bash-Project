# Script Documentation

## Planning
This script is designed to monitor system logs for various security-related events, including SSH login attempts, failed authentication attempts, and potential port scan attempts. It scans the logs to detect these events.

### Proposed timeline
```mermaid
gantt
    title Script Implementation
    dateFormat YYYY-MM-DD
    axisFormat %d/%m
    tickInterval 1day
    excludes    weekends, 2024-05-01


    section Planning
    Planning: 2024-04-30, 2h

    section Script Design
    Script Design: 2h

    section Coding
    Coding: 2h

    section Testing
    Testing: 2024-05-02, 1h

    section Documentation Writing
    Documentation Writing: 2024-04-30, 2d
```

## Requirements
- Bash shell environment
- Systemd journal for log management (typical in modern Linux distributions)
- ufw enabled and configured to log
- rsyslog to create log files

## Script Explanation
The script consists of several functions to monitor different security-related events:

1. **monitor_ssh_login**: Monitors succesful SSH login attempts by searching for lines containing "Accepted password for" in the systemd journal under the `ssh` service.
2. **monitor_failed_auth**: Monitors failed SSH authentication attempts by searching for lines containing "Failed password for" in the systemd journal under the `ssh` service.
3. **monitor_failed_local_login**: Monitors failed local login attempts by searching for lines containing "Failed password for" in the systemd journal.
4. **detect_port_scan**: Detects potential port scan attempts by analyzing network-related logs in the systemd journal. It identifies repeated connections to different ports within a short period.

## Testing
To test the script, follow these steps:
1. Ensure you have Bash installed and the systemd journal is being used for logging on your system.
2. install ufw, enable it's logging functionality and install rsyslog
2. Save the script to a file (e.g., `security_monitor.sh`) and make it executable (`chmod +x security_monitor.sh`).
3. Run the script (`./security_monitor.sh`).
4. Perform various actions such as SSH login attempts, failed authentication attempts, and potential port scans to trigger the monitoring functions.
5. Observe the script's output to verify that it detects and reports these events correctly.

## Example Usage
```bash
./security_monitor.sh
```