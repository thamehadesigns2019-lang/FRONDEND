#!/bin/bash

# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Enable web support (just in case)
flutter config --enable-web

# Build the app
flutter build web --release --no-tree-shake-icons
