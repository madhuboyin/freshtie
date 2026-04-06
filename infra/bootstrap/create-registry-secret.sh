#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="freshtie"
SECRET_NAME="regcred"

DOCKER_SERVER="${DOCKER_SERVER:-ghcr.io}"
DOCKER_USERNAME="${DOCKER_USERNAME:-change-me}"
DOCKER_PASSWORD="${DOCKER_PASSWORD:-change-me}"
DOCKER_EMAIL="${DOCKER_EMAIL:-change-me@example.com}"

kubectl -n "${NAMESPACE}" delete secret "${SECRET_NAME}" --ignore-not-found

kubectl -n "${NAMESPACE}" create secret docker-registry "${SECRET_NAME}" \
  --docker-server="${DOCKER_SERVER}" \
  --docker-username="${DOCKER_USERNAME}" \
  --docker-password="${DOCKER_PASSWORD}" \
  --docker-email="${DOCKER_EMAIL}"

echo "Created docker registry secret '${SECRET_NAME}' in namespace '${NAMESPACE}'."