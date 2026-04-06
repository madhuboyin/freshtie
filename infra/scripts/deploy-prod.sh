#!/usr/bin/env bash
set -euo pipefail

# Move to repo root if run from elsewhere
cd "$(dirname "$0")/../.."

echo "🚀 Validating manifests..."
kubectl apply \
  -f infra/k8s/namespace.yaml \
  -f infra/k8s/configmap.yaml \
  -f infra/k8s/deployment.yaml \
  -f infra/k8s/service.yaml \
  -f infra/k8s/ingress.yaml \
  --dry-run=client

echo "🚀 Deploying to Production (K3s)..."
kubectl apply \
  -f infra/k8s/namespace.yaml \
  -f infra/k8s/configmap.yaml \
  -f infra/k8s/deployment.yaml \
  -f infra/k8s/service.yaml \
  -f infra/k8s/ingress.yaml

echo "⏳ Waiting for rollout..."
kubectl -n freshtie rollout status deployment/freshtie-api --timeout=60s

echo "✅ Deployment complete!"
kubectl -n freshtie get pods -l app=freshtie-api