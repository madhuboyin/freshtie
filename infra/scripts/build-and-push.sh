#!/usr/bin/env bash
set -euo pipefail

# Move to repo root if run from elsewhere
cd "$(dirname "$0")/../.."

REGISTRY="ghcr.io"
REPOSITORY="madhuboyin/freshtie"
IMAGE_NAME="freshtie-api"
IMAGE_TAG="latest"

FULL_IMAGE_NAME="${REGISTRY}/${REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "🚀 Building and pushing Docker image: ${FULL_IMAGE_NAME}"

# Ensure we have a builder instance capable of multi-arch builds
if ! docker buildx inspect default > /dev/null 2>&1; then
    docker buildx create --use
fi

# Build and push using buildx for multi-architecture (linux/amd64, linux/arm64)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --push \
  --tag "${FULL_IMAGE_NAME}" \
  app/backend

echo "✅ Build and push complete!"
