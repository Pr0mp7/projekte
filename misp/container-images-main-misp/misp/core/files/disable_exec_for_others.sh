#!/bin/bash

# Collecting system information
# chmod o-x /bin/uname
# chmod o-x /usr/bin/whoami
# chmod o-x /usr/bin/id
# chmod o-x /bin/hostname
# chmod o-x /bin/ps
# chmod o-x /usr/bin/top
# chmod o-x /usr/bin/lsof
# chmod o-x /bin/netstat
# chmod o-x /sbin/ifconfig
# chmod o-x /sbin/ip
# chmod o-x /bin/df
# chmod o-x /usr/bin/du

# Collecting network information
chmod o-x /usr/sbin/ss

# File system and files
#chmod o-x /bin/grep # backupscript
#chmod o-x /bin/cat
chmod o-x /usr/bin/less
#chmod o-x /usr/bin/head # backupscript
# chmod o-x /usr/bin/tail #used for show logs to stdout

# User and group information
chmod o-x /usr/bin/who
chmod o-x /usr/bin/w
chmod o-x /usr/bin/last
chmod o-x /usr/bin/passwd

# Configuration and log files
chmod o-x /bin/systemctl
chmod o-x /bin/journalctl
chmod o-x /bin/dmesg

# Privilege escalation tools
chmod o-x /usr/bin/su

echo "Execution permissions for 'others' have been removed."
