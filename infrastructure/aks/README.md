> AKS preparation update (20 October 2026): the original resource-group name was rejected; the user then authorized `flughafen-zuerich-poc` for the smaller preparation cluster. See [current deployment status](../aks-preparation/STATUS.md). The larger RTF template remains a separate, uninstalled proposal.

# Azure infrastructure template

**Status: templates only; no installation or provisioning is requested.**

Use the [reusable cluster installer](../cluster-install/README.md) once a supported Kubernetes cluster exists. It bootstraps Argo CD and the stage layout, then optionally deploys the official RTF chart through Argo CD using private vendor inputs. It is locally/render-tested, not yet live-cluster or real-vendor-chart validated.

## Create the Azure infrastructure

`terraform/` contains the separate AKS provisioning configuration for Switzerland North and the existing `flughafen-zürich-poc` resource group. Review the private inputs, permissions, quota, exact RTF-supported version and costs before provisioning. Creation still requires approval; no new AKS cluster has been deployed.

```powershell
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

These commands validate configuration only. They do not provision the cluster or validate Azure access and MuleSoft compatibility.

## Install onto an existing cluster

Follow [infrastructure/cluster-install/README.md](../cluster-install/README.md). Select a site profile and the intended kubeconfig/context; use separate private state per cluster. The installer creates one local Argo CD instance and its Application, so the kubeconfig identifies the destination.

- Foundation mode: Argo CD plus `rtf` and DEV/INT/PROD namespaces, no MuleSoft credentials required.
- RTF mode: provide the real vendor chart/values/registry inputs and supported platform confirmation. Fill site environment IDs and chart lock in Git. Argo CD owns the runtime deployment.
- No Anypoint management plane, ingress controller or Mule applications are included. Application connectivity between sites is not required for the foundation; actual RTF readiness requires its vendor prerequisites.

The previous `runtime-fabric/`, `runtime-namespaces/` and `all-sites/` namespace Terraform roots are reference alternatives. Do not apply them to resources owned by the new installer. UC 1B requires the vendor runtime deployment through Argo CD; Terraform bootstrap is a separate boundary to agree for the demonstration.

The former F4s v2 / 64 GiB configuration is superseded. The current candidate uses configurable Dasv5 nodes (at least 16 GiB RAM), 512 GiB OS disks and a platform-review guard, with spending approval disabled. Previous cost estimates for the former configuration must not be reused. See the template examples for inputs.
