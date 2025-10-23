#!/bin/bash

# Create the cluster
kind create cluster --config kind-config.yaml

# Install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Create ConfigMap for Cloudflare IP ranges
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudflare-ips
  namespace: ingress-nginx
data:
  enable-real-ip: "true"
  use-forwarded-headers: "true"
  forwarded-for-header: "CF-Connecting-IP"
  proxy-real-ip-cidr: "173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,104.16.0.0/13,104.24.0.0/14,172.64.0.0/13,131.0.72.0/22"
EOF

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager

# Apply our base configurations
kubectl apply -f base/cert-manager.yaml
kubectl apply -f base/ingress.yaml

echo "Cluster is ready! Don't forget to:"
echo "1. Add your Cloudflare API token to the cloudflare-api-token-secret in base/cert-manager.yaml"
echo "2. Configure your Cloudflare DNS to point to your cluster IP"
echo "3. Apply your service configurations"
echo ""
echo "Important Cloudflare Settings:"
echo "1. SSL/TLS Mode: Full (strict)"
echo "2. Edge Certificates: Enable Always Use HTTPS"
echo "3. Network: Enable WebSockets if needed"