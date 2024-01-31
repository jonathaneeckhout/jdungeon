#!/bin/bash

scp build/server/jdungeon.x86_64 $1:/root/web/

scp docker/gateway/Dockerfile $1:/root/web/gateway/
scp docker/gateway/docker-compose.yml $1:/root/web/gateway/

scp docker/server/Dockerfile $1:/root/web/server/
scp docker/server/docker-compose.yml $1:/root/web/server/
