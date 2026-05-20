#!/bin/bash
set -e

curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.6-stable.tar.xz -o flutter.tar.xz
tar -xf flutter.tar.xz
export PATH="$PWD/flutter/bin:$PATH"

flutter config --enable-web
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=APP_SCHEME="$APP_SCHEME" \
  --dart-define=APP_HOST="$APP_HOST"
