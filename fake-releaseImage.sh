#!/bin/bash

set -e

export CONTAINER_TEST_IMAGE=shinobidocker
export REGISTRY_IMAGE=releaseImage
export FAKE_CI=true

# ./releaseImage.sh [branch1, branch2, ...] [image1, image2, ...] [DEST_IMAGE_NAME] \
#     [APP_FLAVOR] [FORCE_APP_VERSION] [APP_SPECIAL_VERSIONS] [APP_ISDEFAULT] [APP_SPECIAL_TAGS] [APP_SUFFIX] [APP_DISTRO]

echo "----  DEV-images  ----"
# alpine and debian images
/bin/bash ./gitlab-ci/releaseImage.sh \
    "dev" "alpine,debian" "testimagename" \
    "" "-" "" "false" ""  ""

# Offical image with tags "latest" and "official"
/bin/bash ./gitlab-ci/releaseImage.sh \
    "dev" "official" "testimagename" \
    "" "-" "" "false" "latest-dev"  ""

echo "----  MASTER-images  ----"
# alpine and debian images
/bin/bash ./gitlab-ci/releaseImage.sh \
    "dev" "alpine,debian" "testimagename" \
    "" "image" "" "false" ""  ""

# Offical image with tags "latest" and "official"
#   The official image does not contain any version information!
/bin/bash ./gitlab-ci/releaseImage.sh \
    "dev" "official" "testimagename" \
    "" "-" "" "false" "latest-dev"  ""

/bin/bash ./gitlab-ci/releaseImage.sh \
    "master" "official" "testimagename" \
    "" "-" "" "false" "latest"  ""
