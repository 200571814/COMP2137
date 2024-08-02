#!/bin/bash

verbose=0

if [[ "$1" == "-verbose" ]]; then
    verbose=1
fi

# Function to execute remote commands
execute_remote() {
    local host=$1
    local script=$2
    local options=$3

    if [[ $verbose -eq 1 ]]; then
        scp configure-host.sh remoteadmin@$host:/root
        ssh remoteadmin@$host -- /root/configure-host.sh -verbose $options
    else
        scp configure-host.sh remoteadmin@$host:/root
        ssh remoteadmin@$host -- /root/configure-host.sh $options
    fi
}

# Apply configurations to remote servers
execute_remote server1-mgmt "-name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4"
execute_remote server2-mgmt "-name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3"

# Apply host entries to the local machine
if [[ $verbose -eq 1 ]]; then
    ./configure-host.sh -verbose -hostentry loghost 192.168.16.3
    ./configure-host.sh -verbose -hostentry webhost 192.168.16.4
else
    ./configure-host.sh -hostentry loghost 192.168.16.3
    ./configure-host.sh -hostentry webhost 192.168.16.4
fi
