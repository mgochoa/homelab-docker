# Kubernetes migration for homelab (from Docker Compose)

This repository contains Kubernetes manifests and helper scripts to run your homelab stack locally using Kind and OpenEBS for storage. The original setup used Docker Compose; this repo contains converted manifests and guidance to run them on a local Kind cluster.

Overview
--------
- Kind cluster configuration: `k8s/kind-config.yaml`
- Ingress + TLS (cert-manager + Cloudflare): `k8s/base/ingress.yaml`, `k8s/base/cert-manager.yaml`
- OpenEBS storage classes and setup: `k8s/base/storage-classes.yaml`, `k8s/setup-openebs.sh`
- App manifests: `k8s/apps/*.yaml` (services, PVCs, Deployments/StatefulSets)
- Helper scripts: `k8s/setup.sh`, `k8s/setup-openebs.sh`, `k8s/update-storage.sh`

Quick notes
-----------
- You must create and/or fill secrets before applying the manifests (Cloudflare API token, database passwords, Bitwarden settings). See the "Secrets" section.
- Temporary `*-new.yaml` files were created during conversion for easy diff/inspection. They are safe to remove after you confirm the canonical `*.yaml` files are correct.

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


