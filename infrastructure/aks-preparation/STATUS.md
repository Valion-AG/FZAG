# Deployment blocked — 20 October 2026

Requested: a separate AKS preparation cluster and `mulesoft` namespace in Switzerland North, using only `flughafen-zürich-poc`.

- User approved two F4s v2 nodes / 128 GiB disks, approximately USD 380–410/month running, and asked to leave it running.
- Permissions, initial core quota, SKU availability and real Terraform plan were checked. The plan contained AKS plus its administrator role, no changes or deletions.
- The Azure AKS create API rejected the request with `InvalidParameter`: `The value of parameter resourceGroupName is invalid.` The existing group contains the umlaut `ü`. The supplied node resource-group name was already ASCII.
- The user explicitly declined creating an alternative ASCII-named resource group.
- AKS list after the failed request was empty. Neither `rg-fzag-prep-nodes` nor the proposed alternative group exists. No cluster, node pool, administrator role assignment or namespace was created.
- No alternative resource group, VM cluster or existing-cluster modification is authorized as a substitute.

The retained Terraform and namespace definitions are preparation/reference source. They are **not a successful deployment**. Creation in the required resource group remains blocked until the AKS provider accepts it or the user changes the constraint. No automatic deployment workflow is configured.
