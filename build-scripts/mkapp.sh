#!/usr/bin/env bash


if [ -e "/Applications/Xcode_11.7.app" ]; then
    sudo xcode-select -switch /Applications/Xcode_11.7.app
fi

xcodebuild \
  -project './google-viewer/AlfredGoogleViewer.xcodeproj' \
  -configuration Release \
  -scheme 'AlfredGoogleViewer' \
  -derivedDataPath DerivedData \
  build

cp -r 'DerivedData/Build/Products/Release/AlfredGoogleViewer.app' ./
