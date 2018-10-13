#!/bin/bash

set -e

if [ ! -d ./datadir ]
then
    mkdir -p datadir
    chmod -R 777 datadir
fi

if [ ! -d ./datadir_debian ]
then
    mkdir -p datadir_debian
    chmod -R 777 datadir_debian
fi

if [ ! -d ./videos ]
then
    mkdir -p videos
    chmod -R 777 videos
fi

if [ ! -d ./sqlitedata ]
then
    mkdir -p sqlitedata
    chmod -R 777 sqlitedata
fi

trap "sleep 5 && docker-compose down" INT

if [ -z ${1+x} ]; then
    echo "Usage: ./runGitLabImage.sh [official|alpine|debian]"
else
    docker-compose -f ./docker-compose.gitlab.${1}.yml up --build
fi
