#!/bin/bash
git clone https://github.com/flutter/flutter.git
ls
flutter/bin/flutter clean
flutter/bin/flutter config --enable-web
flutter/bin/flutter channel stable
flutter/bin/flutter upgrade
flutter/bin/flutter doctor
flutter/bin/flutter pub get
flutter/bin/dart run build_runner build --delete-conflicting-outputs
npm install cheerio