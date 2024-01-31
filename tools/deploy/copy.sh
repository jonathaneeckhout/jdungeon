#!/bin/bash

scp build/server/jdungeon.x86_64 $1:/root/web/

scp docker/gateway/Dockerfile.gateway $1:/root/web/
scp docker/server/Dockerfile.server $1:/root/web/

scp docker/web/docker-compose.yml $1:/root/web/
