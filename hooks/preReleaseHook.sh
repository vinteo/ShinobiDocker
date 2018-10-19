#!/bin/bash

set -e

apk add --update --no-cache nodejs git wget
git clone https://gitlab.com/Shinobi-Systems/Shinobi.git ./ShinobiPro

export APP_VERSION=$( node -pe "require('./ShinobiPro/package.json')['version']" )

wget -q https://gitlab.com/MiGoller/docker-tag-creator-script/-/jobs/artifacts/master/raw/createTagList.sh?job=deploy-artifacts-master -O ./createTagList.sh
wget -q https://gitlab.com/MiGoller/docker-tag-creator-script/-/jobs/artifacts/master/raw/releaseDockerImage.sh?job=deploy-artifacts-master -O ./releaseDockerImage.sh
chmod +x *.sh
