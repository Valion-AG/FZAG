# AKS ready — 20 October 2026

| Item | Result |
|---|---|
| Cluster | `aks-fzag-prep` |
| Resource group | `flughafen-zuerich-poc` |
| Node resource group | `rg-fzag-prep-nodes` |
| Region | Switzerland North |
| Version | Kubernetes 1.36.4 |
| Nodes | 2 × Standard_F4s_v2, both Ready |
| OS disks | 128 GiB each, managed Premium_LRS |
| Namespace | `mulesoft`, Active, empty |
| Access | Entra/Azure RBAC; administrator role assigned to the requesting user |
| API allowlist | Office `46.14.148.34/32`; Cloud Shell `134.149.156.75/32` |
| Power/provisioning | Running / Succeeded |

Validation completed: both nodes Ready; all 22 kube-system pods Running with all containers ready; namespace Active; authorization check for creating deployments returned yes; no workloads in `mulesoft`. A fresh Terraform plan for both cluster and namespace returned no changes (detailed exit code 0).

User approved creating the ASCII-named resource group after AKS rejected the original umlaut name. Infrastructure Terraform created three resources (group, AKS, administrator role), followed by the namespace Terraform root. Existing resources in the original resource group were not moved or changed.

The cluster is intentionally **left running**, as requested. Estimate: USD 380–410/month continuously running, excluding existing infrastructure and MuleSoft licensing; not a guaranteed bill or hard cap. No stop/deletion schedule is configured. Initial nodes fit current quota; a future surge upgrade needs additional regional quota.

This is a small preparation cluster, not an RTF installation. No MuleSoft runtime, ingress controller, Argo CD or application workloads were installed here. Future RTF use needs sizing/storage review, vendor access and installation configuration. Terraform source is in Git; private state, plans and kubeconfig are excluded from the published source.

[Open cluster in Azure Portal](https://portal.azure.com/#resource/subscriptions/6f5e5d9c-cd3f-4dec-8ade-410c01c8195f/resourceGroups/flughafen-zuerich-poc/providers/Microsoft.ContainerService/managedClusters/aks-fzag-prep/overview)

API access update: added the user-supplied Cloud Shell IP using a reviewed Terraform plan containing only an in-place allowlist update. Office access was preserved and the namespace remained reachable. Cloud Shell access still needs confirmation from that session; its IP may differ in a future session. No registry password was requested, read or stored by this change.
