# ArgoCD Setup

This guide explains how to use ArgoCD to manage your homelab applications.

## Installation

1. Apply ArgoCD base installation:
```bash
kubectl apply -f k8s/base/argocd.yaml
```

2. Get the initial admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

3. Access ArgoCD UI at: https://argocd.molg.example.com

## Application Structure

The repository is organized to support both plain Kubernetes manifests and Helm charts:

```
k8s/
├── apps/              # Plain Kubernetes manifests
├── base/              # Core infrastructure
│   ├── argocd.yaml           # ArgoCD installation
│   ├── applicationset.yaml   # ApplicationSet configuration
│   └── ...                  # Other base configurations
├── helm-values/       # Helm-based applications
└── kind-config.yaml   # Local cluster configuration
```

## ApplicationSet

All applications are managed through an ApplicationSet, which provides:
- Centralized application management
- Consistent configuration across apps
- Automatic synchronization
- Retry mechanisms for failed deployments

The ApplicationSet includes:
1. Helm-based applications:
   - Homepage
   - Bitwarden
   - Nextcloud
   - Jellyfin
   - N8N
   - Smokeping

2. Git-based applications:
   - Ollama
   - OpenWebUI

To deploy all applications:
```bash
kubectl apply -f k8s/base/applicationset.yaml
```

The ApplicationSet will:
- Create ArgoCD applications automatically
- Use values files from `helm-values/` directory
- Apply retry logic for failed deployments
- Enable automatic pruning and self-healing

## Helm-based Applications

The following applications are deployed using Helm charts:

1. Bitwarden (using k8s-at-home/vaultwarden chart)
   - Includes MariaDB dependency
   - Persistent storage for config and database

2. N8N (using n8n-io/n8n chart)
   - Includes PostgreSQL dependency
   - Ingress configuration
   - Persistent storage

## Adding New Applications

To add a new Helm-based application:

1. Create a new file in `k8s/helm-values/`
2. Define an ArgoCD Application CRD
3. Specify Helm chart source and values
4. Apply the file to your cluster

Example:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://chart-repo.example.com
    chart: my-chart
    targetRevision: 1.0.0
    helm:
      values: |
        # Helm values here
  destination:
    server: https://kubernetes.default.svc
    namespace: default
```

## Syncing Applications

ArgoCD will automatically sync your applications based on the repository state. You can also:

1. Manual sync: Use the ArgoCD UI or CLI
2. Force sync: Override any drift or failed states
3. Selective sync: Choose specific resources to sync

## Troubleshooting

1. Check application status:
```bash
kubectl -n argocd get applications
```

2. View detailed sync status:
```bash
kubectl -n argocd describe application <app-name>
```

3. View ArgoCD logs:
```bash
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-server
```