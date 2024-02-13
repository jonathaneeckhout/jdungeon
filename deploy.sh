#!/bin/bash

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <SSH LOGIN TO SERVER> <ITCH USERNAME / ITCH GAME>"
    echo "Description: Deploy jdungeon server's remotely on a host"
    exit 1
fi

echo ========================= Preparing ===============================
./tools/deploy/prepare.sh $1
echo ========================= Building ===============================
./tools/deploy/build.sh $1
echo ========================= Copying ===============================
./tools/deploy/copy.sh $1
echo ========================= Starting ===============================
./tools/deploy/start.sh $1
echo ========================= Push to Itch.io ===============================
./tools/deploy/push_to_itch.sh $2