#!/bin/bash

compose_file="docker-compose.yml"

# Function to check if the docker-compose file exists
check_and_run() {
    if [ -e "$1/$compose_file" ]; then
        echo "Running 'docker-compose down' in $1"
        cd "$1" && docker-compose down --rmi all --remove-orphans
    else
        echo "No '$compose_file' found in $1. Skipping..."
    fi
}

# Check and run for each directory
check_and_run "/root/web/gateway"
check_and_run "/root/web/server"

rm -rf /root/web

mkdir -p /root/web/gateway
mkdir -p /root/web/server
