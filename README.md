# Kubernetes migration for homelab (from Docker Compose)

This repository contains Kubernetes manifests and helper scripts to run your homelab stack locally using Kind and OpenEBS for storage. The original setup used Docker Compose; this repo contains converted manifests and guidance to run them on a local Kind cluster.

Overview
--------
- Kind cluster configuration: `k8s/kind-config.yaml`
- Ingress + TLS (cert-manager + Cloudflare): `k8s/base/ingress.yaml`, `k8s/base/cert-manager.yaml`
- OpenEBS storage classes and setup: `k8s/base/storage-classes.yaml`, `k8s/setup-openebs.sh`
- ArgoCD GitOps deployment: `k8s/base/argocd.yaml`
- Helm-based applications: `k8s/helm-values/*.yaml`
- Legacy app manifests: `k8s/apps/*.yaml` (for non-Helm applications)
- Helper scripts: `k8s/setup.sh`, `k8s/setup-openebs.sh`, `k8s/update-storage.sh`

For detailed ArgoCD setup and usage, see [ArgoCD Setup Guide](k8s/ARGOCD.md)

Quick notes
-----------
- You must create and/or fill secrets before applying the manifests (Cloudflare API token, database passwords, Bitwarden settings). See the "Environment & Secrets" section.
- Update the domain names in `k8s/base/ingress.yaml` to match your Cloudflare domain
- Temporary `*-new.yaml` files were created during conversion for easy diff/inspection. They are safe to remove after you confirm the canonical `*.yaml` files are correct.

Additional Components
------------------
The following components have been added to complement the main services:

1. OpenWebUI for Ollama (`k8s/apps/openwebui.yaml`):
   - Web interface for Ollama
   - Connects to Ollama service internally
   - Accessible at chat.molg.example.com
   - Persistent storage for user data

2. N8N PostgreSQL database (`k8s/apps/n8n-db.yaml`):
   - StatefulSet for PostgreSQL 16
   - Includes initialization script
   - Health checks and probes
   - Separate non-root user for N8N service

Volume Migration Notes
--------------------
When migrating from Docker Compose to Kubernetes, the following volume paths need to be preserved:

1. Nginx Proxy Manager (replaced by ingress-nginx):
   - ./nginx/data → Not needed, replaced by K8s ingress
   - ./nginx/letsencrypt → Replaced by cert-manager

2. Nextcloud:
   - ./nextcloud/appdata → PVC: nextcloud-config
   - ./nextcloud/data → PVC: nextcloud-data

3. Jellyfin:
   - ./jellyfin/config → PVC: jellyfin-config
   - ./jellyfin/movies → PVC: jellyfin-movies
   - ./sonarr/downloads → Consider separate media PVC

4. Bitwarden:
   - ./bitwarden/bitwarden → PVC: bitwarden-config
   - ./bitwarden/logs → PVC: bitwarden-logs
   - ./bitwarden/data → PVC: bitwarden-db-data (MariaDB)

5. Ollama:
   - ./ollama → PVC: ollama-data

6. Smokeping:
   - ./smokeping/config → PVC: smokeping-config
   - ./smokeping/data → PVC: smokeping-data

7. Homepage:
   - ./homepage/config → PVC: homepage-config

Environment & Secrets
-------------------
Several applications require environment variables and secrets:

0. Cloudflare Configuration:
   - Create a secret for Cloudflare API token:
   ```yaml
   kubectl create secret generic cloudflare-api-token \
     --from-literal=api-token=your_cloudflare_api_token
   ```
   - Update domains in `k8s/base/ingress.yaml`
   - Configure Cloudflare DNS records for all services

1. Bitwarden:
   - Create a secret from `settings.env`
   - Database credentials for MariaDB

2. N8N:
   - PostgreSQL credentials:
     - POSTGRES_USER
     - POSTGRES_PASSWORD
     - POSTGRES_DB
     - POSTGRES_NON_ROOT_USER
     - POSTGRES_NON_ROOT_PASSWORD

3. Nextcloud/Jellyfin:
   - PUID/PGID settings (default: 1000/1000)
   - Timezone configuration

Create the necessary secrets before deploying:
```yaml
# Example secret creation (replace with your actual values)
kubectl create secret generic bitwarden-env --from-file=./settings.env
kubectl create secret generic n8n-db-creds \
  --from-literal=POSTGRES_USER=your_user \
  --from-literal=POSTGRES_PASSWORD=your_password
```

How to use
----------
1. Install dependencies on your workstation (Linux/WSL):
   - kind
   - kubectl
   - helm (optional)
2. Create the Kind cluster:
```bash
cd k8s
kind create cluster --name homelab --config kind-config.yaml
```

3. Set up OpenEBS storage (required for persistent volumes):
```bash
# Apply OpenEBS operator and default storage class
./setup-openebs.sh

# Wait for OpenEBS pods to be ready
kubectl -n openebs wait --for=condition=ready pod --all --timeout=120s
```

4. Apply base infrastructure:
```bash
# Apply storage classes and base configurations
kubectl apply -f base/storage-classes.yaml
kubectl apply -f base/storage.yaml

# Install cert-manager and create ClusterIssuer
kubectl apply -f base/cert-manager.yaml
kubectl apply -f base/ingress.yaml
```

5. Apply application manifests:

Available Applications
--------------------
The following applications have been converted from Docker Compose to Kubernetes:

Core Services:
- Nginx Proxy Manager (Ingress controller replacement)
- Homepage (Dashboard)

Storage & Media:
- Nextcloud (File sharing and collaboration)
- Jellyfin (Media server)

Security & Management:
- Bitwarden (Password manager)
  - Requires MariaDB database (see `bitwarden-db.yaml`)
  - Environment variables from `settings.env`

AI & Automation:
- Ollama (AI model serving)
  - Supports GPU if available
- N8N (Workflow automation)
  - Requires PostgreSQL database
  - Environment variables needed for database configuration

Monitoring:
- Smokeping (Network latency monitoring)

Deployment with ArgoCD
--------------------
1. Install ArgoCD:
```bash
kubectl apply -f k8s/base/argocd.yaml
```

2. Wait for ArgoCD to be ready:
```bash
kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=argocd-server -n argocd
```

3. Deploy the ApplicationSet:
```bash
kubectl apply -f k8s/base/applicationset.yaml
```

4. Get the initial admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

5. Access ArgoCD UI at: https://argocd.molg.example.com

The ApplicationSet will automatically create and manage all applications in the cluster.

Available Applications (Helm Charts)
---------------------------------
The following applications are managed via Helm charts:

1. Core Services:
   - Homepage (`helm-values/homepage.yaml`)
   - Bitwarden (`helm-values/bitwarden.yaml`)

2. Storage & Media:
   - Nextcloud (`helm-values/nextcloud.yaml`)
   - Jellyfin (`helm-values/jellyfin.yaml`)

3. Automation & Monitoring:
   - N8N (`helm-values/n8n.yaml`)
   - Smokeping (`helm-values/smokeping.yaml`)

4. Manual Applications:
   - Ollama and OpenWebUI (no official Helm charts available)
   
Applications will be automatically deployed and managed by ArgoCD based on the repository state.

Important Storage Notes
---------------------
- OpenEBS provides local path provisioner for persistent storage
- Default storage class is set to `openebs-hostpath`
- For safe data migration from Docker volumes:
  1. Stop the source Docker containers
  2. Copy data from Docker volumes to the corresponding PV mount points
  3. Verify permissions on copied data
  4. Start Kubernetes deployments

WSL/PowerShell Users
-------------------
When running in WSL with PowerShell, use the following pattern for commands:
```powershell
wsl -e bash -c "cd /path/to/k8s && ./setup-openebs.sh"
```

