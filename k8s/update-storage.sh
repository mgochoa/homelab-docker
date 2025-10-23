#!/bin/bash
set -euo pipefail

# Ensure OpenEBS install step is run (idempotent)
if [ -x ./k8s/setup-openebs.sh ]; then
  ./k8s/setup-openebs.sh
fi

# Move any temporary -new manifests into place (safe)
for file in k8s/apps/*-new.yaml; do
  [ -e "$file" ] || continue
  dest="${file%-new.yaml}.yaml"
  echo "Moving $file -> $dest"
  mv "$file" "$dest"
done

# Apply all app manifests
kubectl apply -f k8s/apps/

echo "All applications have been updated to use OpenEBS storage classes!"
echo ""
echo "Storage class usage:"
echo "- openebs-db: Used for databases (PostgreSQL, MariaDB, Ollama)"
echo "- openebs-media: Used for media (Jellyfin movies/shows, Nextcloud data)"
echo "- openebs-hostpath: Used for config and small data"
echo ""
echo "To verify the changes:"
echo "  kubectl get pvc -A"
