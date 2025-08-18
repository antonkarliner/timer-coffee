#!/bin/bash
git clone https://github.com/flutter/flutter.git
cd flutter
git checkout 3.19.6
cd ..
ls
flutter/bin/flutter clean
flutter/bin/flutter pub get
flutter/bin/flutter config --enable-web
flutter/bin/flutter channel stable
flutter/bin/flutter upgrade
flutter/bin/flutter doctor
flutter/bin/flutter pub get
flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs
npm install cheerio