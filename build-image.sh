#!/bin/bash
set -e

if [ -z ${1+x} ]; then
    echo "Usage: ./build-image.sh [official|alpine|debian]"
else
    docker build -f ./${1}/Dockerfile -t shinobitest:${1} .
fi
