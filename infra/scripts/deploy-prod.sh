#!/usr/bin/env bash
set -euo pipefail

kubectl apply -k infra/k8s/overlays/prod
kubectl -n freshtie rollout status deployment/freshtie-api