#!/bin/bash

GODOT=~/Programs/Godot_v4.2.1-stable_linux.x86_64
GODOT_NET=~/Programs/Godot_v4.2.1-stable_mono_linux_x86_64/Godot_v4.2.1-stable_mono_linux.x86_64

EXPORT_NAME=jdungeon
EXPORT_DIR=build/
SERVER_EXPORT_DIR=${EXPORT_DIR}server/
WEB_EXPORT_DIR=${EXPORT_DIR}web/

echo $SERVER_EXPORT_DIR

rm -rf $EXPORT_DIR
mkdir -p $SERVER_EXPORT_DIR
mkdir -p $WEB_EXPORT_DIR

$GODOT -v --headless --export-release "Linux/X11" ${SERVER_EXPORT_DIR}${EXPORT_NAME}.x86_64

$GODOT -v --headless --export-release "Web" ${WEB_EXPORT_DIR}index.html
