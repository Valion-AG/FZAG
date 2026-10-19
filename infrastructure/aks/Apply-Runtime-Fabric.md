# Runtime Fabric — use and apply

**One RTF installation per supported cluster**, with separate DEV / INT / PROD application namespaces. Repeat on Azure, ZRH and MCDP, using each infrastructure's own kubeconfig and state. This does not install Omni Gateway or a Private Cloud control plane.

The code is in draft [PR #4](https://github.com/Valion-AG/FZAG/pull/4). Download/check out its branch, `proposal/aks-gitops-20261019`. The working folder is `infrastructure/aks/` inside that checkout; keep `modules/` alongside `runtime-fabric/`.

## What you can apply now vs later

| Phase | Creates | Prerequisites |
|---|---|---|
| Cluster | Azure AKS via `terraform/`; ZRH/MCDP hosting adapters still pending | Cost approval, quota, supported version, infrastructure access |
| **A — prepare** | `rtf` namespace and three site-prefixed application namespaces | Running cluster, authorized kubeconfig, change approval; no MuleSoft activation/license yet |
| **B — install RTF** | Namespace authorizations, agent RoleBindings, registry Secret and official Helm release | Available Anypoint control plane, activation/registry/chart access, appropriate license/entitlement, supported cluster/version and reviewed networking/ingress |

**Currently no new AKS or RTF is deployed.** The existing broker VM uses K3s; do not assume it is a supported RTF installation target. Creating AKS remains subject to the separate cost approval; the namespace-only preparation does not create an Azure cluster.

Choose the exact Kubernetes patch against the intended RTF release **before provisioning the cluster**. The earlier AKS input example's `1.36.4` was illustrative, not a confirmed RTF-supported version.

## Phase A: example for Azure, in PowerShell

Install Terraform 1.16.6 (the tested CLI), kubectl and the target's authentication tools. For AKS also use Azure CLI and kubelogin. Retrieve a private kubeconfig for the approved, already provisioned cluster and verify its context first:

```powershell
kubectl --kubeconfig 'C:/PRIVATE/azure-kubeconfig' --context fzag-azure-runtime get nodes
```

From your checkout's `infrastructure/aks/` folder:

```powershell
$PrivateDir = Join-Path $env:LOCALAPPDATA 'FZAG/private/azure'
New-Item -ItemType Directory -Force $PrivateDir | Out-Null
Copy-Item runtime-fabric/profiles/azure.tfvars.example "$PrivateDir/runtime.tfvars"
```

Edit that private inputs file: set the real kubeconfig path/context and, after checking the intended cluster and approving the namespace changes, set `approved_for_cluster_changes = true`. **Keep `install_runtime_fabric = false`.**

Initialize a separate local PoC state in the private directory, review a saved plan and apply it:

```powershell
terraform -chdir=runtime-fabric init -backend-config="path=$PrivateDir/runtime.tfstate"
terraform -chdir=runtime-fabric plan -var-file="$PrivateDir/runtime.tfvars" -out="$PrivateDir/prepare.tfplan"
terraform -chdir=runtime-fabric apply "$PrivateDir/prepare.tfplan"
```

The `apply` uses that reviewed saved plan. Check that it contains only the intended namespaces for this cluster. The local backend locks one operator's state; use access-controlled encrypted storage and retain a protected backup. If adopting a shared remote backend, change/migrate the backend deliberately before a multi-operator or licensed installation. Do not create a paid storage backend without approval.

Verify:

```powershell
kubectl --kubeconfig 'C:/PRIVATE/azure-kubeconfig' --context fzag-azure-runtime get namespaces rtf fzag-azure-dev fzag-azure-int fzag-azure-prod
```

Expected: four namespaces. **No MuleSoft pods, license, activation or running applications yet.** Phase A does not create a Private Cloud management namespace or prepare a self-hosted control plane.

For ZRH use `profiles/zrh.tfvars.example` and that cluster's private path/context/state. For MCDP use `profiles/mcdp.tfvars.example` and execute locally **inside MCDP**. Do not reuse one initialized working directory against a second site without reinitializing its backend. Prefer a separate working copy and private state directory per site. Do not mix ownership with the older `all-sites/` or `runtime-namespaces/` roots.

## Phase B: once access/licensing is available

1. Verify the exact RTF release, Kubernetes distribution/version, node sizing and ingress controller against MuleSoft's support matrix. A generic Kubernetes namespace module working on OpenShift does not establish RTF support for that platform. Confirm the applicable OpenShift installation path with MuleSoft before using it.
2. Create/register the Runtime Fabric in the intended **Anypoint Runtime Manager** (SaaS for Azure/ZRH, the approved private control plane for MCDP). Obtain the exact chart version, repository access, registry credentials and vendor-generated `values.yml` with activation data and application license. Without an available management plane you cannot complete this step.
3. Obtain DEV/INT/PROD environment IDs and the owning organisation ID. Associate the RTF target with the intended environments as required by the chosen version. These must come from the intended control plane, not from guessed names.
4. Save the vendor values YAML and a valid registry Docker config JSON in the protected private directory. Never commit these files, Terraform state or saved plans. Terraform/Helm state contains sensitive configuration even when plan output is redacted.
5. In the same private `.tfvars`, supply:

```hcl
install_runtime_fabric = true
entitlements_confirmed = true
platform_support_confirmed = true
network_reviewed = true
organization_id = "REAL_ORG_ID"
environment_ids = { dev = "REAL_DEV_ID", int = "REAL_INT_ID", prod = "REAL_PROD_ID" }
chart_version = "EXACT_VERSION_FROM_RUNTIME_MANAGER"
chart_repository = "AUTHENTICATED_VENDOR_REPOSITORY_URL"
repository_username = "VENDOR_REPOSITORY_USER"
repository_password = "VENDOR_REPOSITORY_PASSWORD"
values_file = "C:/PRIVATE/values.yml"
registry_config_file = "C:/PRIVATE/registry-dockerconfig.json"
```

Those are placeholders, not working credentials. The registry JSON must contain the credentials for the registry specified in the vendor values file. Use protected input handling for passwords; do not put them on a command line or in Git.

6. Review required cluster/API, registry, management/monitoring, DNS, ingress and backend paths. This RTF root deliberately does not apply the generic namespace deny-all policies: they would block required RTF communication without the full vendor-specific allowlist. `network_reviewed` confirms the real networking prerequisites have been addressed; it is not an implemented firewall rule.
7. Repeat plan/apply against the **same state** using a new saved plan filename. Terraform labels worker namespaces with their real Anypoint IDs, creates `authorized-namespaces`, binds the agent, creates the pull Secret and installs the pinned `rtf-agent` Helm chart.
8. Check `kubectl -n rtf get pods`, `helm -n rtf status runtime-fabric`, the Runtime Manager status and an actual test Mule deployment. Use the explicit kubeconfig/context for these commands. The first application must be deployed/targeted from Anypoint tooling; this Terraform does not deploy a Mule application.

The `rtf` Helm release, registry Secret and authorization resources are disabled until Phase B. Clustered applications/persistence-gateway variants require additional version-specific permissions/storage; these are not enabled by this root. Destruction protection is enabled; do not remove it for routine operations.

After RTF is installed, do not switch `install_runtime_fabric` back to false to pause it: that requests removal of managed resources and is blocked by destruction protection. For the proposed on-demand AKS operation, stop/start the cluster through AKS instead.

## MCDP

MCDP needs an approved private-control-plane/RTF compatibility and disconnected-operation procedure. It cannot complete RTF activation against a nonexistent SaaS/private platform. To install from a disconnected site, use a locally mirrored chart via `chart_archive`, leave `chart_repository` unset, provide local registry credentials/image references in the vendor values file and set `mcdp_offline_support_confirmed=true` only after vendor confirmation.

Transfer Terraform, signed provider packages (Kubernetes **and Helm**), module source, lock files and approved MuleSoft artifacts through the offline process. Run Terraform and keep its state inside MCDP. No outside controller connection is required by the Terraform code. Offline provider/chart installation has not been tested here.

## Current validation

RTF root: Terraform validate and four mock-provider plan tests pass. Tests establish that preparation installs no MuleSoft release/credentials, missing prerequisites block activation, MCDP preparation remains inactive, and the licensed configuration wires all three authorized worker namespaces before Helm. They do not download the actual private chart or establish vendor support, activation success, live network behaviour or running Mule applications.

Official installation procedure: https://docs.mulesoft.com/runtime-fabric/latest/install-helm
