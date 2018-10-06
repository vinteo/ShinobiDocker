#!/bin/bash

set -e

if [ -z ${1+x} ]; then
    echo "Usage: ./stop-image.sh [official|alpine|debian]"
else
    docker-compose -f ./docker-compose.${1}.yml down
fi
