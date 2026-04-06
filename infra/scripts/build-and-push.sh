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

# Ensure we have a dedicated builder for multi-platform support (docker-container driver)
BUILDER_NAME="freshtie-builder"

if ! docker buildx inspect "${BUILDER_NAME}" >/dev/null 2>&1; then
  echo "🔧 Creating new buildx builder '${BUILDER_NAME}' for multi-architecture support..."
  docker buildx create --name "${BUILDER_NAME}" --driver docker-container --use
  docker buildx inspect --bootstrap
else
  docker buildx use "${BUILDER_NAME}"
fi

# Build and push using buildx for Raspberry Pi architecture (linux/arm64)
docker buildx build \
  --platform linux/arm64 \
  --push \
  --tag "${FULL_IMAGE_NAME}" \
  app/backend

echo "✅ Build and push complete!"

echo "🔄 Triggering rolling restart of Kubernetes deployment..."
kubectl -n freshtie rollout restart deployment/freshtie-api

echo "⏳ Waiting for pods to restart with the new image..."
kubectl -n freshtie rollout status deployment/freshtie-api --timeout=60s

echo "✅ Update successfully deployed!"
