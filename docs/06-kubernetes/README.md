# Stage 6: Kubernetes Cluster (Planned)

## Goal
Bootstrap K8s cluster with kubeadm, deploy application with auto-scaling.

## Planned steps
1. kubeadm init on k8s-master (10.0.0.18)
2. Join k8s-node1/2 (10.0.0.19-20) as workers
3. Install Calico CNI (VXLANCrossSubnet)
4. Deploy app as Deployment + HPA
5. MySQL as StatefulSet with PVC
6. Ingress Controller for external access
7. ConfigMap + Secrets for configuration
8. Helm Chart packaging

## Ansible playbook
- `ansible/k8s_setup.yml` — full cluster bootstrap (5 steps)
  - STEP 1: System prep (modules, sysctl, swap off)
  - STEP 2: containerd installation
  - STEP 3: kubeadm/kubelet/kubectl install
  - STEP 4: Master init + Calico
  - STEP 5: Worker join

## Interview points
- kubeadm vs k3s vs RKE: why kubeadm (closest to production)
- Calico vs Flannel: Calico for network policy + BGP support
- StatefulSet for MySQL: stable identity, persistent storage
- HPA: CPU/memory-based auto-scaling
- RBAC: least privilege for service accounts

## Key files
- `k8s/deployment.yaml` — app deployment
- `k8s/service.yaml` — ClusterIP/NodePort
- `k8s/ingress.yaml` — ingress rules
- `k8s/hpa.yaml` — horizontal pod autoscaler
