#!/bin/bash
set -e

# Pin Flutter to the stable release used for local development instead of
# cloning master HEAD: master commits can leave flutter_tools uncompilable,
# which breaks every flutter command in CI. The release archive ships a
# prebuilt flutter_tools snapshot, so the tool never has to compile itself.
# Bump FLUTTER_VERSION together with the local SDK when upgrading.
FLUTTER_VERSION=3.47.5

rm -rf flutter flutter.tar.xz
curl -f --retry 3 -o flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
tar xf flutter.tar.xz
rm flutter.tar.xz
flutter/bin/flutter --version

flutter/bin/flutter config --enable-web
flutter/bin/flutter pub get
flutter/bin/dart run build_runner build --delete-conflicting-outputs
npm install cheerio
