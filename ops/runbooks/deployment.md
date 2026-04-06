# Operational Runbook: Deployment & Rollback

## Deployment Process

### Automated Deployment (GitHub Actions)
1. Ensure `CI` workflow is passing on the `main` branch.
2. Go to **Actions** -> **Deploy Prod**.
3. Click **Run workflow** and select the `main` branch.
4. The workflow will:
   - Build multi-arch (AMD64/ARM64) Docker images.
   - Push to GitHub Container Registry (GHCR).
   - Update the K8s manifest image tag.
   - Apply to the Raspberry Pi K3s cluster.
   - Verify the rollout status.

### Manual Local Deployment
Run the script from the repository root:
```bash
./infra/scripts/deploy-prod.sh
```
*Note: Requires `kubectl` access to the cluster.*

## Rollback Process

### Using Rollout Undo
If a deployment fails or introduces a critical bug, you can undo the last rollout:
```bash
kubectl -n freshtie rollout undo deployment/freshtie-api
```

### Rollback to a Specific Revision
1. List available revisions:
   ```bash
   kubectl -n freshtie rollout history deployment/freshtie-api
   ```
2. Rollback to a specific revision (e.g., revision 5):
   ```bash
   kubectl -n freshtie rollout undo deployment/freshtie-api --to-revision=5
   ```

## Infrastructure Configuration

### Required Secrets (GitHub Actions)
- `KUBECONFIG`: Full content of your cluster's kubeconfig file.
- `GITHUB_TOKEN`: Provided automatically by GitHub Actions (used for GHCR auth).

### Environment Variables
Environment variables are managed in `infra/k8s/base/configmap.yaml`.

## Troubleshooting

### Check Pod Logs
```bash
./infra/scripts/logs.sh
```

### Restart Service
```bash
./infra/scripts/restart.sh
```

### Common Issues
- **ImagePullBackOff**: Ensure GHCR permissions are correct or the image tag exists.
- **CrashLoopBackOff**: Check logs for application errors (port conflicts, missing env vars).
- **RPi Resource Limits**: If pods are pending, check cluster resources: `kubectl top nodes`.
