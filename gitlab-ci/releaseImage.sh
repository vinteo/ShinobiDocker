#!/bin/bash

set -e

#   ./releaseImage.sh "$SOURCE_IMAGE_NAME" "$DEST_IMAGE_NAME" "$APP_FLAVOR" "$APP_VERSION" "$APP_SPECIAL_VERSIONS" "$APP_ISDEFAULT" "$APP_SPECIAL_TAGS" "$APP_SUFFIX" "$APP_DISTRO"

###############################################################################
#   Mandatory commandline arguments:
#       [branch1, branch2, ...] :   List of branches to process
#       [image1, image2, ...]   :   List of images to process. The Dockerfiles must reside within the named subdirectory.
#       DEST_IMAGE_NAME         :   The name of the destination image WITHOUT ANY TAG
#       APP_FLAVOR              :   Set to tag images for different variants like "official", "iot", whatever you want.
#       FORCE_APP_VERSION       :   Set to the application's version information
#       APP_SPECIAL_VERSIONS    :   Add these comma-seperated version information to the list of app's version based tag list
#       APP_ISDEFAULT           :   Set to true, if you want to include default tags like the version information only.
#       APP_SPECIAL_TAGS        :   Add these comma-seperated tags like "latest","stable"
#       APP_SUFFIX              :   Add a suffix to each APP_FLAVOR based tag, but not to the default tags.
#       APP_DISTRO              :   Subfolder containing the Dockerfile
###############################################################################

if [ -z ${1+x} ]; then
    echo "Usage: ./releaseImage.sh [branch1, branch2, ...] [image1, image2, ...] [DEST_IMAGE_NAME] [APP_FLAVOR] [FORCE_APP_VERSION] [APP_SPECIAL_VERSIONS] [APP_ISDEFAULT] [APP_SPECIAL_TAGS] [APP_SUFFIX] [APP_DISTRO]"
    exit 1
else
    branches=( ${1//,/ } )
    images=( ${2//,/ } )
    DEST_IMAGE_NAME=${3}
    APP_FLAVOR=${4}
    FORCE_APP_VERSION=${5}
    APP_SPECIAL_VERSIONS=${6}
    APP_ISDEFAULT=${7}
    APP_SPECIAL_TAGS=${8}
    APP_SUFFIX=${9}
    APP_DISTRO=${10}

    for branch in "${branches[@]}"; do
        # For each branch ...
        echo "Releasing image(s) for branch ${branch}:"
        for image in "${images[@]}"; do
            # Releasing image ...

            # Set destination image name
            if [ "${branch}" = "master" ]; then
                export NEW_DEST_IMAGE_NAME="${CONTAINER_TEST_IMAGE}"
            else
                export NEW_DEST_IMAGE_NAME="${CONTAINER_TEST_IMAGE}/${branch}"
            fi

            echo "  - Releasing ${CONTAINER_TEST_IMAGE}-${branch}:${image} ..."

            # Set version information
            case "${FORCE_APP_VERSION}" in
                "-")
                    # NO VERSION TAGGING!
                    export APP_VERSION="-"
                    ;;
                
                image)
                    # Get Version information from image
                    export APP_VERSION=$( docker inspect -f "{{range .Config.Env}}{{println .}}{{end}}" ${CONTAINER_TEST_IMAGE}-${branch}:${image} | grep APP_VERSION | awk '{split($0,a,"="); print a[2]}' )
                    ;;
                
                *)
                    # Set to given version information
                    export APP_VERSION=${FORCE_APP_VERSION}
            esac

            echo "    - Version $APP_VERSION ..."
            
            # Set Docker image build arguments
            export APP_FLAVOR="${image}"
            export APP_DISTRO="${image}"

            # Tag and push the image
            if [ "${FAKE_CI}" = "true" ]; then
                # ./createTagList.sh "${branch}" "$APP_VERSION" "" "false" "" "" "${image}"
                # ./createTagList.sh "${branch}-${image}" "$APP_VERSION" "$APP_SPECIAL_VERSIONS" "$APP_ISDEFAULT" "$APP_SPECIAL_TAGS" "$APP_SUFFIX" "${image}"
                # ./createTagList.sh "$APP_FLAVOR" "$APP_VERSION" "$APP_SPECIAL_VERSIONS" "$APP_ISDEFAULT" "$APP_SPECIAL_TAGS" "$APP_SUFFIX" "$APP_DISTRO"
                
                $( ./createTagList.sh "$APP_FLAVOR" "$APP_VERSION" "$APP_SPECIAL_VERSIONS" "$APP_ISDEFAULT" "$APP_SPECIAL_TAGS" "$APP_SUFFIX" "$APP_DISTRO" )

                echo "    - Image name: ${NEW_DEST_IMAGE_NAME}:[${TAG_LIST}]"
            else
                echo "    - 1"
                # ./releaseDockerImage.sh \
                #     "${CONTAINER_TEST_IMAGE}-${branch}:${image}" "${DEST_IMAGE_NAME}" "${branch}" \
                #     "$APP_VERSION" "" "false" "" "" "${branch}-${image}"
            fi
        done
    done
fi
