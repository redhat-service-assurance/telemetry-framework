#!/usr/bin/env bash

# NOTE: this script should not be run directly. It is used by the demo_setup.sh
#       script via Ansible script module.

while getopts ":t:" opt; do
    case $opt in
        t) time_server="$OPTARG"
        ;;
    esac
done

# network manager
yum install NetworkManager -y
systemctl enable NetworkManager.service
systemctl start NetworkManager.service

# journald
cat > /etc/systemd/journald.conf <<EOF
[Journal]
SystemMaxUse=500M
SystemMaxFileSize=10M
EOF

journalctl --vacuum-size=500M
systemctl restart systemd-journald.service

# chronyd
if [ -v time_server  ]; then
    cat > /etc/chrony.conf <<EOF
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
server ${time_server} iburst

# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped in the first three updates
# if its offset is larger than 1 second.
makestep 1.0 3

# Enable kernel synchronization of the real-time clock (RTC).
rtcsync

# Specify directory for log files.
logdir /var/log/chrony
EOF

    systemctl restart chronyd.service
fi