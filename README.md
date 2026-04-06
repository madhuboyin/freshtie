# Freshtie

Freshtie is a conversation continuity assistant that helps users know what to say before talking to someone.

## Repo structure

- `app/ios` — iOS app
- `app/backend` — backend service(s)
- `infra/k8s` — Kubernetes manifests
- `docs` — FRD, architecture, and decisions
## Operations

- [Deployment & Rollback Runbook](ops/runbooks/deployment.md)
- [Backend Documentation](app/backend/README.md)

## Environment

Currently only:

- `prod`

Namespace:

- `freshtie`

## Deploy

```bash
kubectl apply -k infra/k8s/overlays/prod