#!/bin/sh

set -e

###############################################################################
#   Get the app's version information
###############################################################################

# Install nodejs for version information, etc.
apk add --update --no-cache nodejs

# Get the corresponding package.json file for the app
wget -q https://gitlab.com/Shinobi-Systems/Shinobi/raw/master/package.json -O ./package.json

# Get the app's version information
APP_VERSION=$(node -pe "require('./package.json')['version']")

###############################################################################
#   Build list of tags for the image.
###############################################################################
echo "-------------------------------------------------------------------------------"
echo "Image tagging:"

# The flavor tag
APP_FLAVOR="${1}"
echo "- Flavor: ${APP_FLAVOR}"

# Split APP_VERSION for naming the tags
version=( ${APP_VERSION//./ } )
echo "- Version: ${APP_VERSION}"

# Special versions?
APP_SPECIAL_VERSIONS="${2}"
sversions=( ${APP_SPECIAL_VERSIONS//,/ } )
echo "- Special versions: ${APP_SPECIAL_VERSIONS}"

# Is default image type?
APP_ISDEFAULT="${3}"
echo "- Is default flavor: ${APP_ISDEFAULT}"

# Any special tags?
APP_SPECIAL_TAGS="${4}"
stags=( ${APP_SPECIAL_TAGS//,/ } )
echo "- Special tags: ${APP_ISDEFAULT}"

### Build tag array
tags=()

# Add tags for version AND flavor
if [ -n "${APP_FLAVOR}" ]; then
    for tag in {"${APP_VERSION}-${APP_FLAVOR}","${version[0]}.${version[1]}-${APP_FLAVOR}","${version[0]}-${APP_FLAVOR}","${APP_FLAVOR}"}; do  
#        echo " + ${tag}"
        tags+=( ${tag} )
    done

    # Any special version?
    if [ -n "${APP_SPECIAL_VERSIONS}" ]; then
        for tag in "${sversions[@]}"; do  
#            echo " + ${tag}-${APP_FLAVOR}"
            tags+=( ${tag}-${APP_FLAVOR} )
        done
    fi
fi

# Add tags for version for default image type only!
if [ "${APP_ISDEFAULT}" = "true" ]; then
    for tag in {"${APP_VERSION}","${version[0]}.${version[1]}","${version[0]}"}; do  
#        echo " + ${tag}"
        tags+=( ${tag} )
    done

    # Any special version?
    if [ -n "${APP_SPECIAL_VERSIONS}" ]; then
        for tag in "${sversions[@]}"; do  
#            echo " + ${tag}"
            tags+=( ${tag} )
        done
    fi
fi

# Add special tags
if [ -n "${APP_SPECIAL_TAGS}" ]; then
    for tag in "${stags[@]}"; do  
#        echo " + ${tag}"
        tags+=( ${tag} )
    done
fi

# List all tags
echo "Tags to build:"
for tag in "${tags[@]}"; do
    echo "- ${tag}"
done

echo "-------------------------------------------------------------------------------"

###############################################################################
#   Build, tag and push the images.
###############################################################################
echo "-------------------------------------------------------------------------------"
echo "Build, tag and push the images:"

# Login to Docker Hub
echo "- Logout from GitLab image repository ..."
docker logout
echo "- Login to Docker Hub ..."
docker login -u "$DH_REGISTRY_USER" -p "$DH_REGISTRY_PASSWORD" $DH_REGISTRY

# Build the Docker image with tag "$CI_COMMIT_REF_SLUG-$CI_JOB_ID"
echo "- Build image $DH_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG-$CI_JOB_ID ..."
docker build \
    --build-arg ARG_APP_VERSION=$APP_VERSION \
    --build-arg ARG_APP_CHANNEL=$CI_COMMIT_REF_SLUG \
    --build-arg ARG_APP_COMMIT=$CI_COMMIT_SHA \
    --build-arg ARG_BUILD_DATE="$COMMIT_TIME_ISO" \
    -t "$DH_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG-$CI_JOB_ID" .
#docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG-$CI_JOB_ID"

# Tag and push image for each tag in list
echo "- Tagging image:"
for tag in "${tags[@]}"; do
    echo "  - $DH_REGISTRY_IMAGE:${tag} ..."
    docker tag "$DH_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG-$CI_JOB_ID" "$DH_REGISTRY_IMAGE":${tag}
    docker push "$DH_REGISTRY_IMAGE":${tag}
done

echo "-------------------------------------------------------------------------------"

echo "Build succeeded!"
