#!/bin/bash

./tools/deploy/prepare.sh $1
./tools/deploy/copy.sh $1
./tools/deploy/start.sh $1