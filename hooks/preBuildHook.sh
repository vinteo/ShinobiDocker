#!/bin/bash

set -e

apk add --update --no-cache nodejs git tar xz

# Clone the Shinobi Pro repositiory
git clone https://gitlab.com/Shinobi-Systems/Shinobi.git ./ShinobiPro

# Get the current version information for the app
export APP_VERSION=$( node -pe "require('./ShinobiPro/package.json')['version']" )

chmod +x *.sh
