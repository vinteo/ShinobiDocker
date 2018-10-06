#!/bin/bash

set -e

#   buildImageDockerHub.sh APP_FLAVOR APP_VERSION APP_SPECIAL_VERSIONS APP_ISDEFAULT APP_SPECIAL_TAGS APP_SUFFIX APP_DISTRO
#   Official release:   ./buildImageDockerHub.sh "official" "git" "" "false" "latest" "" "official"
#   Alpine release:     ./buildImageDockerHub.sh "alpine" "git" "" "false" "" "" "alpine"
#   Debian release:     ./buildImageDockerHub.sh "debian" "git" "" "false" "" "" "debian"

###############################################################################
#   Get the app's version information
###############################################################################

# Install nodejs for version information, etc.
apk add --update --no-cache nodejs

# Split APP_VERSION for naming the tags
APP_VERSION="${2}"

if [ "${APP_VERSION}" = "git" ]; then
    # Get the corresponding package.json file for the app
    wget -q https://gitlab.com/Shinobi-Systems/Shinobi/raw/master/package.json -O ./package.json

    # Get the app's version information
    APP_VERSION=$( node -pe "require('./package.json')['version']" )
    echo $APP_VERSION

    rm ./package.json
fi

###############################################################################
#   Build list of tags for the image.
###############################################################################

echo "-------------------------------------------------------------------------------"
echo "Image tagging:"

# The flavor tag
APP_FLAVOR="${1}"
echo "- Flavor: ${APP_FLAVOR}"

# Split APP_VERSION for naming the tags
MY_VERSION=( ${APP_VERSION//./ } )
echo "- Version: ${APP_VERSION}"

# Special versions?
APP_SPECIAL_VERSIONS="${3}"
sversions=( ${APP_SPECIAL_VERSIONS//,/ } )
echo "- Special versions: ${APP_SPECIAL_VERSIONS}"

# Is default image type?
APP_ISDEFAULT="${4}"
echo "- Is default flavor: ${APP_ISDEFAULT}"

# Any special tags?
APP_SPECIAL_TAGS="${5}"
stags=( ${APP_SPECIAL_TAGS//,/ } )
echo "- Special tags: ${APP_SPECIAL_TAGS}"

# Suffix
APP_SUFFIX="${6}"
echo "- Tag suffix: ${APP_SUFFIX}"

# APP_FLAVOR + APP_SUFFIX
APP_FLAVOR_S=${APP_FLAVOR}

if [ -n "${APP_SUFFIX}" ]; then
    APP_FLAVOR_S="${APP_FLAVOR_S}${APP_SUFFIX}"
fi

# Node version
APP_DISTRO="${7}"
echo "- Linux disto: ${APP_DISTRO}"

### Build tag array
tags=()

# Add special tags
if [ -n "${APP_SPECIAL_TAGS}" ]; then
    for tag in "${stags[@]}"; do
        echo " + ${tag}"
        tags+=( ${tag} )
    done
fi

# Add tags for version for default image type only!
if [ "${APP_ISDEFAULT}" = "true" ]; then
    for tag in {"${MY_VERSION[0]}","${MY_VERSION[0]}.${MY_VERSION[1]}","${APP_VERSION}"}; do
        echo " + ${tag}"
        tags+=( ${tag} )
    done

    # Any special version?
    if [ -n "${APP_SPECIAL_VERSIONS}" ]; then
        for tag in "${MY_VERSION[@]}"; do
            echo " + ${tag}"
            tags+=( ${tag} )
        done
    fi
fi

# Add tags for version AND flavor
if [ -n "${APP_FLAVOR_S}" ]; then
    if [ -n "${APP_FLAVOR}" ]; then
        echo " + ${APP_FLAVOR_S}"
        tags+=( ${APP_FLAVOR_S} )
    fi

    for tag in {"${MY_VERSION[0]}-${APP_FLAVOR_S}","${MY_VERSION[0]}.${MY_VERSION[1]}-${APP_FLAVOR_S}","${APP_VERSION}-${APP_FLAVOR_S}"}; do
        echo " + ${tag}"
        tags+=( ${tag} )
    done

    # Any special version?
    if [ -n "${APP_SPECIAL_VERSIONS}" ]; then
        for tag in "${sversions[@]}"; do
            echo " + ${tag}-${APP_FLAVOR_S}"
            tags+=( ${tag}-${APP_FLAVOR_S} )
        done
    fi
fi

# List all tags
echo "Tags to build:"
for tag in "${tags[@]}"; do
    echo "- ${tag}"
done

echo "-------------------------------------------------------------------------------"

###############################################################################
#   Build, tag and push the image.
###############################################################################
echo "-------------------------------------------------------------------------------"
echo "Build and tag the image:"

# Login to Docker Hub
echo "- Logout from GitLab image repository ..."
docker logout $CI_REGISTRY
echo "- Login to Docker Hub ..."
docker login -u "$DH_REGISTRY_USER" -p "$DH_REGISTRY_PASSWORD" $DH_REGISTRY

for tag in "${tags[@]}"; do

    if [ "${BUILT_TAG}" = "" ]; then
        # Build the Docker image with tag "$CI_REGISTRY_IMAGE:${BUILT_TAG}"
        BUILT_TAG=${tag}
        echo "- Build image $DH_REGISTRY_IMAGE:${BUILT_TAG} ..."

        if [ -n "${APP_FLAVOR}" ]; then
            IMAGE_TYPE="${APP_FLAVOR}-"
        else
            IMAGE_TYPE=""
        fi

        docker build \
            --build-arg ARG_APP_VERSION=$APP_VERSION \
            --build-arg ARG_APP_CHANNEL=$CI_COMMIT_REF_SLUG \
            --build-arg ARG_APP_COMMIT=$CI_COMMIT_SHA \
            --build-arg ARG_BUILD_DATE="$BUILD_DATE" \
            --build-arg ARG_FLAVOR="$IMAGE_TYPE" \
            -f "./${APP_DISTRO}/Dockerfile" \
            -t "$DH_REGISTRY_IMAGE:${BUILT_TAG}" .
    else
        # Tag and push image for each tag in list
        echo "- Tagging image:"
        echo "  - $DH_REGISTRY_IMAGE:${tag} ..."
        docker tag "$DH_REGISTRY_IMAGE:${BUILT_TAG}" "$DH_REGISTRY_IMAGE:${tag}"
    fi
done

# Build the Docker image with tag "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG-${BUILT_TAG}"
echo "Push image and tags:"
for tag in "${tags[@]}"; do
    echo "  - $DH_REGISTRY_IMAGE:${tag} ..."
    docker push "$DH_REGISTRY_IMAGE:${tag}"
done

echo "-------------------------------------------------------------------------------"
echo "Building and tagging sequence:"
for tag in "${tags[@]}"; do
    echo "  - $DH_REGISTRY_IMAGE:${tag} "
done

echo "-------------------------------------------------------------------------------"
echo "Build succeeded!"
