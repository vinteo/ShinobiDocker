#!/bin/bash

set -e

if [ -z ${1+x} ]; then
    echo "Usage: ./buildImage.sh [branch1, branch2, ...] [image1, image2, ...]"
    exit 1
else
    branches=( ${1//,/ } )
    images=( ${2//,/ } )

    export BUILD_DATE=$(date +"%Y.%m.%d")

    for branch in "${branches[@]}"; do
        # Clone each branch and build the wanted images
        echo "  - Cloning repository ..."
        rm -rf ./ShinobiPro
        git clone -b ${branch} https://gitlab.com/Shinobi-Systems/Shinobi.git ./ShinobiPro
        
        # Get the current version information for the app
        export APP_VERSION=$( node -pe "require('./ShinobiPro/package.json')['version']" )
        echo "  - Setting APP_VERSION to ${APP_VERSION} ..."

        for image in "${images[@]}"; do
            echo "  - Building image: ${CONTAINER_TEST_IMAGE}-${branch}:${image} ..."
            docker build --pull -f ./${image}/Dockerfile -t $CONTAINER_TEST_IMAGE-${branch}:${image} \
                --build-arg ARG_APP_VERSION=$APP_VERSION \
                --build-arg ARG_APP_CHANNEL=$CI_COMMIT_REF_SLUG \
                --build-arg ARG_APP_COMMIT=$CI_COMMIT_SHA \
                --build-arg ARG_BUILD_DATE="$BUILD_DATE" \
                --build-arg ARG_FLAVOR="${image}" \
                --build-arg ARG_APP_BRANCH="${branch}" .

            echo "  - Pushing image to GitLab repository: ${CONTAINER_TEST_IMAGE}-${branch}:${image} ..."
            if [ "${FAKE_CI}" = "true" ]; then
                echo "    fake --> docker push ${CONTAINER_TEST_IMAGE}-${branch}:${image} ..."
            else
                docker push ${CONTAINER_TEST_IMAGE}-${branch}:${image}
            fi
        done
    done
fi
