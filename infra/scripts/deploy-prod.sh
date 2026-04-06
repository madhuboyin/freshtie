#!/usr/bin/env bash
set -euo pipefail

# Move to repo root if run from elsewhere
cd "$(dirname "$0")/../.."

echo "🚀 Validating manifests..."
kubectl apply -k infra/k8s/overlays/prod --dry-run=client

echo "🚀 Deploying to Production (K3s)..."
kubectl apply -k infra/k8s/overlays/prod

echo "⏳ Waiting for rollout..."
kubectl -n freshtie rollout status deployment/freshtie-api --timeout=60s

echo "✅ Deployment complete!"
kubectl -n freshtie get pods -l app=freshtie-api