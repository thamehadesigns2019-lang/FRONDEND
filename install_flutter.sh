#!/bin/bash

echo "Downloading Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter Setup..."
flutter config --no-analytics
flutter doctor -v

echo "Detailing Dependencies..."
flutter pub get

echo "Building Web App..."
flutter build web --release
