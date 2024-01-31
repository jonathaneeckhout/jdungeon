#!/bin/bash

GODOT=~/Programs/Godot_v4.2.1-stable_linux.x86_64
REMOTE_SCRIPT=./tools/deploy/remote_prepare_script.sh

$GODOT -v --headless --export-release "Linux/X11" build/linux/jdungeon.x86_64

echo "Executing remote commands..."
ssh $1 'bash -s' < $REMOTE_SCRIPT
echo "Commands executed successfully."
