#!/bin/bash

set -e

export CONTAINER_TEST_IMAGE=shinobidocker
export FAKE_CI=true

/bin/bash ./gitlab-ci/buildImage.sh "dev" "official,alpine,debian"
