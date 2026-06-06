#!/bin/bash

set -e

if kind get clusters | grep -q "^kind$"; then
    kind delete cluster --name kind
fi

kind create cluster --config cluster.yml

kind load docker-image todoapp:1.0.8 --name kind

helm repo add traefik https://traefik.github.io/charts
helm repo update

helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --wait

helm upgrade --install todoapp ./infrastructure/todoapp \
  --namespace todoapp \
  --create-namespace \
  -f infrastructure/todoapp/values.yaml \
  -f infrastructure/todoapp/secrets.yaml

kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=traefik \
  -n traefik \
  --timeout=120s

kubectl port-forward service/traefik -n traefik 80:80 > /dev/null 2>&1 &