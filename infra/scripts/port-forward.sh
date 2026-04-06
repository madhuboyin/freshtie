#!/usr/bin/env bash
set -euo pipefail

kubectl -n freshtie port-forward svc/freshtie-api 3000:80