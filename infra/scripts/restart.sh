#!/usr/bin/env bash
set -euo pipefail

kubectl -n freshtie rollout restart deployment/freshtie-api
kubectl -n freshtie rollout status deployment/freshtie-api