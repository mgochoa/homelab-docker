#!/bin/bash

# Create directories for OpenEBS storage
sudo mkdir -p /var/openebs/local
sudo mkdir -p /var/openebs/media
sudo mkdir -p /var/openebs/db

# Set permissions
sudo chmod -R 777 /var/openebs

# Install OpenEBS operator
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml

# Wait for OpenEBS pods to be ready
echo "Waiting for OpenEBS pods to be ready..."
kubectl wait --for=condition=Ready pod -l openebs.io/component-name=openebs-localpv-provisioner -n openebs --timeout=300s

# Apply our storage classes
kubectl apply -f base/storage-classes.yaml

# Create the directories on the node
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: init-openebs-dirs
spec:
  containers:
  - name: init
    image: busybox
    command: 
    - sh
    - -c
    - "mkdir -p /var/openebs/{local,media,db} && chmod -R 777 /var/openebs"
    volumeMounts:
    - name: host-path
      mountPath: /var/openebs
  volumes:
  - name: host-path
    hostPath:
      path: /var/openebs
  restartPolicy: Never
EOF

# Wait for the init pod to complete
kubectl wait --for=condition=Ready pod/init-openebs-dirs --timeout=60s

# Clean up the init pod
kubectl delete pod init-openebs-dirs

echo "OpenEBS setup completed!"
echo "Storage classes created:"
kubectl get storageclass | grep openebs