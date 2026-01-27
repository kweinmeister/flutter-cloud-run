#!/bin/bash
set -e

# Ensure we are in the project root by checking for workspace definition
if [ ! -f "pubspec.yaml" ] || ! grep -q "workspace:" "pubspec.yaml"; then
  echo "❌ Error: This script must be run from the root of the workspace (where the root pubspec.yaml is)."
  echo "   Current directory: $(pwd)"
  exit 1
fi

echo "🚀 Deploying 'todo-app' to Cloud Run (us-central1)..."

# OS-Only Deployment: Builds locally, deploys binary.

echo "🔨 Building project locally..."

# 1. Build Frontend
echo "   Building Flutter Web..."
cd frontend
flutter build web --wasm
cd ..

# 2. Prepare Build Directory
BUILD_DIR="build_deploy"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR/bin

# 3. Compile Backend (Cross-compile to Linux)
echo "   Compiling Backend for Linux..."
dart compile exe backend/bin/server.dart -o $BUILD_DIR/bin/server --target-os=linux --target-arch=x64

# 4. Copy Assets
echo "   Copying assets..."
cp -r frontend/build/web $BUILD_DIR/public

echo "🚀 Deploying to Cloud Run (OS Only)..."

# Default region
REGION=${REGION:-us-central1}

# Deploy pre-built artifact
gcloud beta run deploy todo-app \
  --source $BUILD_DIR \
  --region $REGION \
  --labels dev-tutorial=flutter-cloud-run \
  --allow-unauthenticated \
  --no-build \
  --base-image=osonly24 \
  --command=bin/server


echo "✅ Deployment complete."

