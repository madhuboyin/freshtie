#!/usr/bin/env bash
set -euo pipefail

kubectl -n freshtie logs -l app=freshtie-api -f --tail=200