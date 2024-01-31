#!/bin/bash

compose_file="docker-compose.yml"
users_file_path="/root/web/users.json"
users_tmp_path="/tmp/users.json"

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
check_and_run "/root/web"

if [ -e "$users_file_path" ]; then
    echo "File '$users_file_path' exists. Moving it to $users_tmp_path."
    mv "$users_file_path" "$users_tmp_path"
else
    echo "File '$users_file_path' does not exist. No need to move."
fi

rm -rf /root/web
mkdir -p /root/web

if [ -e "$users_tmp_path" ]; then
    echo "File '$users_tmp_path' exists. Moving it to $users_file_path."
    mv "$users_tmp_path" "$users_file_path"
else
    echo "File '$users_tmp_path' does not exist. Creating empty one"
    echo "{}" >/root/web/users.json
fi
