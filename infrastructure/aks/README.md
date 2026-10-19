# Runtime Fabric: developer quickstart

Terraform provisions cluster infrastructure. Argo CD reconciles the vendor RTF chart and runtime configuration from Git. Anypoint manages the registered fabric and Mule applications.

**Status:** infrastructure code is available; no new AKS cluster or RTF installation has been deployed. The RTF Argo CD Application, protected secret integration and exact supported chart/platform selection are pending. The GitOps examples below describe the target configuration, not an executable RTF deployment.

## Validate locally

Requires Git and Terraform. From the repository root:

```powershell
cd infrastructure/aks
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
terraform -chdir=runtime-fabric init -backend=false
terraform -chdir=runtime-fabric test
```

Expected: valid infrastructure configuration and three passing mocked namespace/guard tests. These commands do not provision resources, contact a real Kubernetes cluster or validate the vendor chart.

## Configure infrastructure

Azure target: **Switzerland North**, resource group **flughafen-zürich-poc**. Start with one runtime cluster and separate DEV / INT / PROD application stages.

- `terraform/`: AKS infrastructure; review `terraform.tfvars.example` and keep actual inputs/state private. Confirm the exact RTF-supported Kubernetes version, permissions, quota and costs before provisioning. The example version is not confirmed for RTF. Billable creation still requires approval.
- ZRH/MCDP: cluster provisioning depends on the infrastructure selected later. Verify the actual distribution and installation track with MuleSoft.
- `runtime-fabric/`: legacy namespace-only bootstrap/reference. Direct RTF installation is disabled. Do not use it to manage namespaces that Argo CD will own.

Infrastructure provisioning is separate from Argo synchronization; merging runtime configuration does not create AKS. No infrastructure auto-apply pipeline is configured here.

## Configure the deployment target

Use a separate Argo CD Application per site. Its source selects the Git configuration; its destination selects the existing registered cluster.

Illustrative Application `spec` excerpt (placeholder path and endpoint):

```yaml
spec:
  project: fzag-runtime
  source:
    repoURL: https://github.com/Valion-AG/FZAG.git
    targetRevision: main
    path: deployments/azure/runtime-fabric
  destination:
    server: https://YOUR-AKS-API-ENDPOINT
    namespace: rtf
  syncPolicy:
    automated:
      prune: false
      selfHeal: true
```

Before enabling synchronization:

- Register the cluster and repository with Argo CD; configure an AppProject permitting the source and destination. The example project `fzag-runtime` must be created or replaced.
- Implement the referenced Git source using the pinned, supported vendor chart and reviewed values. The example folder is not supplied by this proposal. Validate the selected chart's Argo rendering behavior and lifecycle requirements.
- Deliver chart/registry credentials, activation data and licensing through the agreed protected integration. Do not commit secrets or invent chart secret-reference fields.
- Define worker namespaces, real organization/environment IDs and required authorizations separately. `destination.namespace: rtf` is the default for runtime components, not the DEV/INT/PROD stage mapping; explicit manifest namespaces take precedence.

For ZRH, use its own source configuration and registered cluster endpoint. Isolated MCDP requires confirmed offline/private-control-plane compatibility and internal Git, registry and Argo CD. The Azure region belongs to Terraform infrastructure configuration, not the Argo destination namespace.

## Deploy and verify

Once the missing integration is implemented, merge the site configuration into the tracked branch. With the example automatic sync policy, Argo CD reconciles it and repairs drift. If automatic sync is disabled, trigger an Argo CD sync instead.

Verify:

1. Argo CD: correct destination, expected revision, **Synced**, **Healthy**.
2. Anypoint Runtime Manager: fabric registered and connected; correct environment associations.
3. Runtime/application checks: expected namespace authorization and end-to-end test traffic. Argo health alone does not prove successful Anypoint registration or application connectivity.

UC 1B requires deployment/reconciliation through Argo CD using the manufacturer's chart/operator. Do not replace this with manual `kubectl apply`, `helm install` or Terraform `helm_release`. Read-only `kubectl get`, `describe` and `logs` can support verification. Agree the bootstrap boundary before the demonstration.

## Change examples

| Change | Configuration to update |
|---|---|
| Deploy to Azure instead of ZRH | Site-specific Application source and registered cluster destination |
| Upgrade RTF | Pinned vendor chart version and compatible values; validate vendor upgrade requirements |
| Roll back | Revert the relevant Git change, subject to vendor rollback and backup requirements |
| Add an application stage | Environment mapping, worker namespace and authorizations; not just the Application namespace |
| Add MCDP | Internal sources/destination and verified disconnected installation configuration |

Additional prerequisites: [Apply-Runtime-Fabric.md](Apply-Runtime-Fabric.md). The older `all-sites/` and `runtime-namespaces/` roots are infrastructure references, not the UC 1B RTF deployment path. This scope does not install a private management plane, Omni Gateway or Mule applications.
