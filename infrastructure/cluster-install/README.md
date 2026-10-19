# Runtime Fabric deployment templates

**Template-only: nothing is being installed or activated.** All example approval/install flags remain `false`. No active GitHub deployment workflow is configured by this package.

## What is prepared?

| Layer | Template | Result when deliberately applied later |
|---|---|---|
| Azure infrastructure | [`../aks/terraform/`](../aks/terraform/) | AKS in Switzerland North and the existing resource group |
| Shared cluster bootstrap | [`bootstrap/`](bootstrap/) | Argo CD, its renderer and the site Application |
| Stage layout | [`charts/foundation/`](charts/foundation/) | `rtf`, DEV, INT and PROD namespaces |
| Runtime Fabric | [`renderer/`](renderer/) + private vendor chart/values | Official RTF resources reconciled by Argo CD |
| Site parameters | [`profiles/`](profiles/) and [`sites/`](sites/) | Separate Azure, ZRH and MCDP inputs |

The same cluster bundle is reused per target; each cluster has its own kubeconfig/context, state and activation inputs. DEV/INT/PROD namespaces do not themselves create Anypoint environments or provide network isolation.

## What must be filled in later?

| Input | Location |
|---|---|
| Target cluster/context; approval flags | Private copy of `profiles/<site>.tfvars.example` |
| Organization and DEV/INT/PROD environment IDs | `sites/<site>/values.yaml` |
| Vendor chart version and SHA-256 | `sites/<site>/vendor-chart.lock` |
| Reviewed nonsecret RTF settings | `sites/<site>/rtf-overrides.yaml` |
| Real vendor chart, activation/license values and registry credentials | Private directory outside Git; see [operations](OPERATIONS.md) |
| Azure administrator, exact supported patch, network allowlist and provisioning approval | Private copy of `../aks/terraform/terraform.tfvars.example` |

Azure sizing now uses a candidate baseline of two `Standard_D4as_v5` nodes and 512 GiB provisioned OS disks per node. This replaces the unsuitable 8 GiB F4s/64 GiB disk proposal. It is a hardware candidate, not vendor certification or a final cost estimate. Check allocatable resources, actual free space, chart compatibility, regional SKU availability, quota including upgrade surge, and current costs before provisioning. Both platform review and spending approval default to false.

## Coverage by target

| Target | Prepared | Still depends on |
|---|---|---|
| Azure | AKS infrastructure adapter + shared Helm-based runtime bundle | Approved sizing/costs and real MuleSoft inputs |
| ZRH | Shared runtime bundle and site profile | Hosting choice, supported existing cluster and exact installation track |
| MCDP | Shared runtime bundle and site profile with offline guard | Vendor-confirmed disconnected/private-plane compatibility, internal sources and supported installation track |

This bundle implements the **Helm installation track**. A platform requiring the vendor's OpenShift operator needs that supported adapter; generic namespaces are not proof of RTF support. The self-hosted Anypoint management plane, ingress controller, Mule applications, application connectivity and on-premises cluster provisioning are outside this template package. They must be supplied/reviewed before the relevant live deployment. No supported air-gap deployment is claimed yet.

## Later deployment flow

1. Complete the selected site's inputs and vendor/platform prerequisites.
2. Review infrastructure costs/quotas and authorize any billable provisioning.
3. Provision the cluster if needed, then bootstrap it using its site profile and separate private state.
4. Argo CD creates the stage layout and, when explicitly enabled with real inputs, applies the vendor RTF chart.
5. Validate readiness and registration separately from later application connectivity.

Exact commands are in [OPERATIONS.md](OPERATIONS.md); **they are for later use**. No manual `kubectl apply` or `helm install` is required for RTF. Terraform bootstrap is a separate tender boundary to agree. Git-triggered infrastructure automation still needs its identity, state and approval-gate setup; storing these templates in Git does not automatically execute them.

[Validation evidence](VALIDATION.md): mocked Terraform, Helm rendering and a synthetic chart only. Actual cluster bootstrap, real vendor chart, registration and disconnected operation remain untested.

Sources: [RTF requirements](https://docs.mulesoft.com/runtime-fabric/latest/limitations-self), [Azure Dasv5 specifications](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/general-purpose/dasv5-series).
