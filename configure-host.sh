#!/bin/bash

verbose=0

# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        -verbose)
            verbose=1
            shift
            ;;
        -name)
            name="$2"
            shift 2
            ;;
        -ip)
            ip="$2"
            shift 2
            ;;
        -hostentry)
            hostentry_name="$2"
            hostentry_ip="$3"
            shift 3
            ;;
        *)
            echo "Invalid option: $1"
            exit 1
            ;;
    esac
done

# Function to set the hostname
set_hostname() {
    local desired_name=$1
    if [ "$(hostname)" != "$desired_name" ]; then
        echo "$desired_name" > /etc/hostname
        hostname "$desired_name"
        if grep -q "127.0.1.1" /etc/hosts; then
            sed -i "s/127.0.1.1 .*/127.0.1.1 $desired_name/" /etc/hosts
        else
            echo "127.0.1.1 $desired_name" >> /etc/hosts
        fi
        logger "Hostname changed to $desired_name"
        [ $verbose -eq 1 ] && echo "Hostname changed to $desired_name"
    else
        [ $verbose -eq 1 ] && echo "Hostname is already $desired_name"
    fi
}

# Function to set the IP address
set_ip() {
    local desired_ip=$1
    local interface=$(ip -o -4 route show to default | awk '{print $5}')
    current_ip=$(ip -o -4 addr show $interface | awk '{print $4}' | cut -d/ -f1)
    if [ "$current_ip" != "$desired_ip" ]; then
        sed -i "s/$current_ip/$desired_ip/" /etc/netplan/*.yaml
        netplan apply
        if grep -q "$desired_ip" /etc/hosts; then
            sed -i "s/$current_ip/$desired_ip/" /etc/hosts
        else
            echo "$desired_ip $(hostname)" >> /etc/hosts
        fi
        logger "IP address changed to $desired_ip"
        [ $verbose -eq 1 ] && echo "IP address changed to $desired_ip"
    else
        [ $verbose -eq 1 ] && echo "IP address is already $desired_ip"
    fi
}

# Function to set a host entry in /etc/hosts
set_hostentry() {
    local name=$1
    local ip=$2
    if ! grep -q "$name" /etc/hosts; then
        echo "$ip $name" >> /etc/hosts
        logger "Host entry added: $name $ip"
        [ $verbose -eq 1 ] && echo "Host entry added: $name $ip"
    else
        [ $verbose -eq 1 ] && echo "Host entry $name already exists"
    fi
}

# Ignore TERM, HUP, and INT signals
trap "" TERM HUP INT

# Apply configurations
[ ! -z "$name" ] && set_hostname "$name"
[ ! -z "$ip" ] && set_ip "$ip"
[ ! -z "$hostentry_name" ] && [ ! -z "$hostentry_ip" ] && set_hostentry "$hostentry_name" "$hostentry_ip"
