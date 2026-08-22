# K8s Manifests

## Files
- `namespace.yaml` — opslab namespace
- `deployment.yaml` — PHP web app (2 replicas, liveness/readiness probes)
- `service.yaml` — ClusterIP service
- `ingress.yaml` — Nginx Ingress for external access
- `hpa.yaml` — Auto-scaling (2-10 pods, CPU>70% or memory>80%)

## Planned
- `mysql-statefulset.yaml` — MySQL with PVC
- `configmap.yaml` — App configuration
- `secret.yaml` — Database credentials (base64 encoded)
- `helm/` — Helm Chart for one-command deploy

## Usage
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

# Check
kubectl get pods -n opslab
kubectl get hpa -n opslab
```
