# AKS deployment in progress — 20 October 2026

The user authorized the new `flughafen-zuerich-poc` resource group after Azure rejected the original umlaut name. The previous resource-group restriction was superseded for this AKS deployment.

- Region: Switzerland North.
- Cluster: `aks-fzag-prep`; node resource group: `rg-fzag-prep-nodes`.
- Two F4s v2 nodes, 128 GiB managed OS disk per node; Free control-plane tier; Kubernetes 1.36.4.
- Approved running estimate: USD 380–410/month, excluding existing infrastructure and licenses. User requested leaving the cluster running.
- Reviewed saved Terraform plan: three additions (resource group, AKS, administrator role), no changes/deletions.
- Cluster creation is in progress. Namespace creation and validation follow after readiness.
- This is a preparation cluster with an empty `mulesoft` namespace, not a sized or activated RTF installation.
