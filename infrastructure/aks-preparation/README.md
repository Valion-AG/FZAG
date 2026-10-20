# Small AKS preparation cluster

**Deployed and validated:** AKS is running and the empty `mulesoft` namespace is active. See [STATUS.md](STATUS.md).

Scope: a separate AKS cluster in Switzerland North, newly authorized resource group `flughafen-zuerich-poc`, and an empty namespace named `mulesoft`. This is not the larger RTF runtime template and does not install MuleSoft, Argo CD or application workloads.

Approved on 20 October 2026: two F4s v2 nodes, managed 128 GiB OS disks, Free AKS management tier; leave running after validation. Budget estimate USD 380–410/month while running, excluding existing infrastructure and licenses. It is not a hard spending cap. Stop-state estimate USD 50–80/month; stopping was not requested.

- Cluster: `aks-fzag-prep`; node resource group: `rg-fzag-prep-nodes`.
- API access restricted to the approved administrator CIDRs; Entra/Azure RBAC, local accounts disabled.
- `cluster/` provisions the infrastructure; `namespace/` manages only the empty namespace. Keep state and kubeconfig outside Git, with separate state for these two roots.
- No automatic GitHub infrastructure deployment workflow is configured. The source configuration is versioned here; this initial deployment is executed with Terraform.
- Two F4s v2 nodes provide 8 GiB RAM each, below the current RTF node requirements. Future RTF use needs reviewed sizing, storage, licensing and vendor artifacts. The namespace name alone does not register or activate a fabric.
- Initial nodes need 8 vCPUs. Current regional quota has exactly 8 free cores; a future one-node surge upgrade needs a quota increase first. No quota change or extra node is silently requested.
- No deletion is authorized. `prevent_destroy` guards are retained; cleanup requires a separate reviewed action.

Deployment and validation evidence is recorded in [STATUS.md](STATUS.md). The separate [RTF templates](../cluster-install/README.md) remain unchanged in purpose.

## Connect

Requires Azure CLI, kubectl and Azure kubelogin. Sign in as the authorized account, then run:

```powershell
az login
az account set --subscription 6f5e5d9c-cd3f-4dec-8ade-410c01c8195f
az aks get-credentials --resource-group flughafen-zuerich-poc --name aks-fzag-prep --context aks-fzag-prep
kubelogin convert-kubeconfig -l azurecli
kubectl config set-context aks-fzag-prep --namespace=mulesoft
kubectl --context aks-fzag-prep get nodes
kubectl --context aks-fzag-prep get namespace mulesoft
```

API access is limited to the approved office IP and the added Cloud Shell session IP (see STATUS.md). If your egress IP changes, update the reviewed Terraform allowlist before connecting. Do not run `terraform init/apply` from a fresh clone with empty state against these existing resources: retain/use the existing protected state or perform a deliberate reviewed state migration/import.
