# AKS GitOps quickstart

This is a lightweight Kubernetes demonstration on `aks-fzag-prep`. **It is not RTF, a Mule runtime, or the PCE experiment VM.** RTF is not installed yet.

## Change replicas

Edit [`workload/values.yaml`](workload/values.yaml) in GitHub:

```yaml
replicas: 2
```

Commit to `main`. Argo CD application **fzag-aks-demo** automatically reconciles the Deployment. Change back to `replicas: 1` to scale down. CPU and memory requests/limits are in the same file. Argo CD checks Git approximately every 30 seconds; image pulls and startup add time. No manual kubectl apply or helm install is used for workload changes.

The app lives in namespace `fzag-k8s-demo`. The prepared `mulesoft` namespace remains separate. Changing this file does not add/remove AKS nodes. Two ready replicas alone do not prove node-level HA. Deleting an object in Git requires reviewed prune because automatic pruning is disabled.

## Observe

Using your authorized AKS kubeconfig:

```bash
kubectl -n argocd get applications fzag-aks-demo
kubectl -n fzag-k8s-demo get deployment,pods
kubectl -n argocd port-forward service/argocd-server 18081:80
```

Open http://localhost:18081. Username: `admin`; obtain the initial password privately from the `argocd-initial-admin-secret` Secret in namespace `argocd`. Never commit passwords or kubeconfig files. The UI is a ClusterIP service accessible through port-forward, not a public load balancer.

Optional workload browser check:

```bash
kubectl -n fzag-k8s-demo port-forward service/gitops-demo 18080:80
```

Open http://localhost:18080. Read-only kubectl observation/port-forward is separate from the Git-driven deployment flow.

## Bootstrap and later RTF

`bootstrap/` uses Terraform to install Argo CD and its root Application once. Use the exact target context `aks-fzag-prep` and private local state. Inspect existing Argo/Helm releases before applying this to another cluster. Do not initialize a second state against an already-managed installation. Bootstrap is a separate infrastructure step, not a Git-triggered Terraform pipeline.

The chart and app definitions are in Git; live workloads continuously reconcile from Git. The bootstrap itself is Terraform-managed, not self-managed by Argo CD. This proves Kubernetes GitOps replication, not vendor RTF installation or all UC 1B requirements.

For actual Mule application replicas later, see [RTF application templates](../rtf-apps/README.md). They require installed compatible RTF, Anypoint Controller, private credentials and a real Exchange artifact. Do not edit RTF-generated Deployments directly.
