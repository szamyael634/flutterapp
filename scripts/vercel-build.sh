#!/bin/bash
set -ex

export CI=true
export HOME="$PWD/.vercel-home"
mkdir -p "$HOME"

echo "Downloading Flutter SDK..."
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.6-stable.tar.xz -o flutter.tar.xz

echo "Extracting Flutter SDK..."
tar -xf flutter.tar.xz
export PATH="$PWD/flutter/bin:$PATH"

echo "Configuring Git safe directory for Flutter SDK..."
git config --global --add safe.directory "$PWD/flutter"

echo "Flutter version..."
flutter --version

echo "Configuring Flutter for CI..."
flutter --suppress-analytics config --no-analytics
flutter --suppress-analytics config --enable-web

echo "Resolving Dart and Flutter packages..."
flutter --suppress-analytics pub get

echo "Building Flutter web bundle..."
flutter --suppress-analytics build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=APP_SCHEME="$APP_SCHEME" \
  --dart-define=APP_HOST="$APP_HOST"
