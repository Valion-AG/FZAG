# Small AKS preparation cluster

**BLOCKED:** Azure rejected the required resource-group name during creation. The user declined a different group. Nothing was created; see [STATUS.md](STATUS.md).

Scope: a separate AKS cluster in Switzerland North, existing resource group `flughafen-zürich-poc`, and an empty namespace named `mulesoft`. This is not the larger RTF runtime template and does not install MuleSoft, Argo CD or application workloads.

Approved on 20 October 2026: two F4s v2 nodes, managed 128 GiB OS disks, Free AKS management tier; leave running after validation. Budget estimate USD 380–410/month while running, excluding existing infrastructure and licenses. It is not a hard spending cap. Stop-state estimate USD 50–80/month; stopping was not requested.

- Cluster: `aks-fzag-prep`; node resource group: `rg-fzag-prep-nodes`.
- API access restricted to the approved administrator CIDRs; Entra/Azure RBAC, local accounts disabled.
- `cluster/` provisions the infrastructure; `namespace/` manages only the empty namespace. Keep state and kubeconfig outside Git, with separate state for these two roots.
- No automatic GitHub infrastructure deployment workflow is configured. The source configuration is versioned here; this initial deployment is executed with Terraform.
- Two F4s v2 nodes provide 8 GiB RAM each, below the current RTF node requirements. Future RTF use needs reviewed sizing, storage, licensing and vendor artifacts. The namespace name alone does not register or activate a fabric.
- Initial nodes need 8 vCPUs. Current regional quota has exactly 8 free cores; a future one-node surge upgrade needs a quota increase first. No quota change or extra node is silently requested.
- No deletion is authorized. `prevent_destroy` guards are retained; cleanup requires a separate reviewed action.

Deployment and validation status is recorded in `STATUS.md` after execution. The separate [RTF templates](../cluster-install/README.md) remain unchanged in purpose.
