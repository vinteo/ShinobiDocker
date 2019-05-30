#!/bin/bash

set -e

source ./fake-environment.env

export CONTAINER_TEST_IMAGE
export FAKE_CI

if [ "$WORK_MICROSERVICES" = "true" ]; then
    echo "==========================================================================="
    echo "                          MICROSERVICE images"
    echo "==========================================================================="
    # /bin/bash ./gitlab-ci/buildImage.sh "master,dev" "microservice-alpine,microservice-arch,microservice-debian"
    /bin/bash ./gitlab-ci/buildImage.sh "$SHINOBI_BRANCHES_MICROSERVICES" "microservice-alpine,microservice-arch,microservice-debian"
fi

if [ "$WORK_OFFICIAL" = "true" ]; then
    echo "==========================================================================="
    echo "                            OFFICIAL images"
    echo "==========================================================================="
    # /bin/bash ./gitlab-ci/buildImage.sh "master,dev" "official,alpine,debian"
    /bin/bash ./gitlab-ci/buildImage.sh "$SHINOBI_BRANCHES_OFFICIAL" "official,alpine,debian"
fi
