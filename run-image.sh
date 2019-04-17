#!/bin/bash

set -e

if [ -z ${1+x} ]; then
    echo "Usage: ./run-image.sh [official|alpine|debian]"
else
    if [ ! -d ./datadir ]; then
        mkdir -p datadir
        chmod -R 777 datadir
    fi

    if [ ! -d ./microservice_datadir ]; then
        mkdir -p microservice_datadir
        chmod -R 777 microservice_datadir
    fi

    if [ ! -d ./datadir_debian ]; then
        mkdir -p datadir_debian
        chmod -R 777 datadir_debian
    fi

    if [ ! -d ./microservice_datadir_debian ]; then
        mkdir -p microservice_datadir_debian
        chmod -R 777 microservice_datadir_debian
    fi

    if [ ! -d ./videos ];then
        mkdir -p videos
        chmod -R 777 videos
    fi

    docker-compose -f ./docker-compose.${1}.yml up --build
fi
