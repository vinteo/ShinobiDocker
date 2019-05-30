#!/bin/bash

set -e

source ./fake-environment.env

export CONTAINER_TEST_IMAGE
export DH_REGISTRY_IMAGE
export FAKE_CI

# ./releaseImage.sh [branch1, branch2, ...] [image1, image2, ...] [DEST_IMAGE_NAME] \
#     [APP_FLAVOR] [FORCE_APP_VERSION] [APP_SPECIAL_VERSIONS] [APP_ISDEFAULT] [APP_SPECIAL_TAGS] [APP_SUFFIX] [APP_DISTRO]

if [ "$WORK_MICROSERVICES" = "true" ]; then
    echo "==========================================================================="
    echo "                          MICROSERVICE images"
    echo "==========================================================================="

    # echo "Releasing debian and archlinux images ..."
    # /bin/bash ./gitlab-ci/releaseImage.sh "master,dev" "microservice-debian,microservice-arch" "$DH_REGISTRY_IMAGE" "" "image" "" "false" ""  ""
    # echo "Releasing alpine images ..."
    # /bin/bash ./gitlab-ci/releaseImage.sh "master" "microservice-alpine" "$DH_REGISTRY_IMAGE" "" "image" "" "false" "microservice"  ""
    # /bin/bash ./gitlab-ci/releaseImage.sh "dev" "microservice-alpine" "$DH_REGISTRY_IMAGE" "" "image" "" "false" "microservice-dev"  ""

    echo "Releasing debian and archlinux images ..."
    /bin/bash ./gitlab-ci/releaseImage.sh "$SHINOBI_BRANCHES_MICROSERVICES" "microservice-debian,microservice-arch" "$DH_REGISTRY_IMAGE" "" "image" "" "false" ""  ""
    echo "Releasing alpine images ..."
    if [[ $SHINOBI_BRANCHES_MICROSERVICES == *"master"* ]]; then
        /bin/bash ./gitlab-ci/releaseImage.sh "master" "microservice-alpine" "$DH_REGISTRY_IMAGE" "" "image" "" "false" "microservice"  ""
    fi
    if [[ $SHINOBI_BRANCHES_MICROSERVICES == *"dev"* ]]; then
        /bin/bash ./gitlab-ci/releaseImage.sh "dev" "microservice-alpine" "$DH_REGISTRY_IMAGE" "" "image" "" "false" "microservice-dev"  ""
    fi
fi

if [ "$WORK_OFFICIAL" = "true" ]; then
    echo "==========================================================================="
    echo "                            OFFICIAL images"
    echo "==========================================================================="

    # echo "Releasing alpine and debian images ..."
    # /bin/bash ./gitlab-ci/releaseImage.sh "master,dev" "alpine,debian" "$DH_REGISTRY_IMAGE" "" "image" "" "false" "" ""
    # echo "Releasing official images ..."
    # /bin/bash ./gitlab-ci/releaseImage.sh "master" "official" "$DH_REGISTRY_IMAGE" "" "-" "" "false" "latest" ""
    # /bin/bash ./gitlab-ci/releaseImage.sh "dev" "official" "$DH_REGISTRY_IMAGE" "" "-" "" "false" "latest-dev" ""

    echo "Releasing alpine and debian images ..."
    /bin/bash ./gitlab-ci/releaseImage.sh "$SHINOBI_BRANCHES_OFFICIAL" "alpine,debian" "$DH_REGISTRY_IMAGE" "" "image" "" "false" "" ""
    echo "Releasing official images ..."
    if [[ $SHINOBI_BRANCHES_OFFICIAL == *"master"* ]]; then
        /bin/bash ./gitlab-ci/releaseImage.sh "master" "official" "$DH_REGISTRY_IMAGE" "" "-" "" "false" "latest" ""
    fi
    
    if [[ $SHINOBI_BRANCHES_OFFICIAL == *"dev"* ]]; then
        /bin/bash ./gitlab-ci/releaseImage.sh "dev" "official" "$DH_REGISTRY_IMAGE" "" "-" "" "false" "latest-dev" ""
    fi
fi
