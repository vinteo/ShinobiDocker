#!/bin/bash

set -e

if [ -z ${1+x} ]; then
    echo "Usage: ./pullImage.sh [branch1, branch2, ...] [image1, image2, ...]"
    exit 1
else
    branches=( ${1//,/ } )
    images=( ${2//,/ } )

    for branch in "${branches[@]}"; do
        # For each branch ...
        echo "Pulling image(s) for branch ${branch}:"
        for image in "${images[@]}"; do
            # Pull image for tagging, etc.
            echo "  - Pulling ${CONTAINER_TEST_IMAGE}-${branch}_${image} ..."
            if [ "${FAKE_CI}" = "true" ]; then
                echo "    fake --> docker pull ${CONTAINER_TEST_IMAGE}-${branch}_${image} ..."
            else
                docker pull ${CONTAINER_TEST_IMAGE}-${branch}_${image}
            fi
        done
    done
fi
