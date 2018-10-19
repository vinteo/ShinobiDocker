#!/bin/bash

set -e

apk add --update --no-cache nodejs git tar xz

# Clone the Shinobi Pro repositiory
git clone https://gitlab.com/Shinobi-Systems/Shinobi.git ./ShinobiPro

# Get the current version information for the app
export APP_VERSION=$( node -pe "require('./ShinobiPro/package.json')['version']" )

# Get ffmpeg
wget -q https://cdn.shinobi.video/installers/ffmpeg-release-64bit-static.tar.xz -O ./ffmpeg-release-64bit-static.tar.xz
tar xpvf ./ffmpeg-release-64bit-static.tar.xz -C ./
mkdir -p ./ffmpeg
cp -f ./ffmpeg-3.3.4-64bit-static/ff* ./ffmpeg
chmod +x ./ffmpeg
rm -f ffmpeg-release-64bit-static.tar.xz
rm -rf ./ffmpeg-3.3.4-64bit-static

chmod +x *.sh
