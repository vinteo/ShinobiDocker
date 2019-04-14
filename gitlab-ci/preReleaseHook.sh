#!/bin/bash

set -e

wget -q https://gitlab.com/MiGoller/docker-tag-creator-script/-/jobs/artifacts/master/raw/createTagList.sh?job=deploy-artifacts-master -O ./createTagList.sh
wget -q https://gitlab.com/MiGoller/docker-tag-creator-script/-/jobs/artifacts/master/raw/releaseDockerImage.sh?job=deploy-artifacts-master -O ./releaseDockerImage.sh
chmod +x *.sh
