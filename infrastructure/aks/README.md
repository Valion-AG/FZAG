# Runtime Fabric: quickstart

**Workflow: Terraform provisions infrastructure -> Git describes the runtime -> Argo CD installs and reconciles it.**

## Current status

The infrastructure proposal was merged in [PR #4](https://github.com/Valion-AG/FZAG/pull/4); merging code does not deploy Runtime Fabric. No new AKS cluster or MuleSoft software has been deployed. A deployable RTF Argo CD Application is still pending MuleSoft access, supported chart/platform selection and protected secret delivery.

## How to use it

Start with **Azure only**. ZRH and MCDP come later, once their infrastructure is known.

### Try it now: download and check the code

With Git and Terraform installed, open PowerShell:

```powershell
git clone https://github.com/Valion-AG/FZAG.git
cd FZAG/infrastructure/aks
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

Already cloned it? Use your existing checkout instead of cloning again.

**Expected:** `The configuration is valid.` You now have the files and have checked their syntax. These commands download Terraform providers but create no Azure resources. They do not check Azure permissions, quota or MuleSoft compatibility.

### Later: create the Azure cluster

AKS provides the computers that run Runtime Fabric. Terraform creates this infrastructure.

For our example: use **Switzerland North**, resource group **flughafen-zürich-poc**, and one Azure runtime cluster with DEV / INT / PROD application stages.

Before creation, check costs, quota, permissions and the RTF-supported Kubernetes version. The example version in the code is not confirmed for RTF. **Creation still needs cost approval**, so there is no deployment command to run at this stage.

### Later: install Runtime Fabric through Git

We first need MuleSoft access, activation data, a supported chart version and the missing Argo CD deployment configuration. Keep licenses and passwords outside Git.

### How to create the pull request

GitHub calls a merge request a **pull request (PR)**. Once the deployment files are ready:

1. Open [FZAG on GitHub](https://github.com/Valion-AG/FZAG).
2. From the branch selector, create a branch from `main`, for example `deploy/azure-runtime`.
3. Open the deployment file you want to change, click the pencil icon, edit it and choose **Commit changes** to your new branch.
4. Open **Pull requests -> New pull request**. Select `main` as the **base** and `deploy/azure-runtime` as the **compare** branch.
5. Review the changed files, then click **Create pull request**. Example title: "Install Runtime Fabric in Azure".
6. After review, click **Merge pull request**. If repository rules require checks or another reviewer, complete those first.

The PR changes configuration; it does not select a deployment target by itself. Editing this README only changes documentation.

### Where do I tell it to deploy?

An **Argo CD Application** connects configuration in Git to a Kubernetes cluster. The following is an illustrative Application `spec` excerpt, **not a ready-to-use deployment file**:

```yaml
spec:
  source:
    repoURL: https://github.com/Valion-AG/FZAG.git
    targetRevision: main
    path: deployments/azure/runtime-fabric
  destination:
    server: https://YOUR-AKS-API-ENDPOINT
    namespace: rtf
```

| Setting | What you enter |
|---|---|
| `targetRevision` | The branch Argo CD watches, here `main` |
| `path` | The Git folder containing the deployment configuration |
| `destination.server` | The API endpoint of the intended cluster, already registered with Argo CD |
| `destination.namespace` | The default namespace for namespaced resources, here `rtf` |

The example folder and endpoint are placeholders. The completed Application needs additional settings, the real vendor chart integration and protected secret delivery. The cluster must exist, and Argo CD must have access and an AppProject permitting the source and destination. The `rtf` namespace hosts runtime components; DEV/INT/PROD application namespaces and authorizations are configured separately. A namespace explicitly set in a manifest takes precedence over the Application's default.

For example, Azure and ZRH would have separate Applications pointing to their respective clusters and site configuration. Isolated MCDP uses its internal Git, registry and controller. You do not choose the region in the pull request form: Terraform configures the Azure infrastructure region; the Application points to the resulting cluster.

### What happens after merging?

With automatic synchronization and self-healing configured:

**Merge into main -> Argo CD detects the change -> deploys to the configured cluster -> check Synced / Healthy.**

Without automatic synchronization, merge first and then click **Sync** in Argo CD. Neither option involves a manual `kubectl apply` or `helm install`.

Open the Application in Argo CD to check its **Destination**, **Sync status**, **Health** and deployed resources. Then check in Anypoint Runtime Manager that the fabric is registered and connected. Argo health alone does not prove Anypoint registration or working application traffic.

**Current limit:** the RTF Application, target-cluster connection and protected MuleSoft credentials are still pending. A README merge does not deploy RTF, and this example cannot deploy anything yet.

### Examples of everyday changes

| What you want | What you do once GitOps is ready |
|---|---|
| Install RTF in Azure | Merge the reviewed Azure runtime configuration; Argo CD installs it |
| Upgrade RTF | Change the pinned chart version to a supported release in Git; review and merge |
| Undo an update | Revert the Git change, following vendor rollback and backup requirements |
| Add ZRH | Prepare its supported cluster and separate site configuration, then deploy through Argo CD |
| Add isolated MCDP | Confirm offline support first; use internal Git, registry and Argo CD inside MCDP |

For example, an upgrade PR changes the chart version from the current approved release to the next approved release. After merging, watch Argo CD perform the update. You do not run `helm install` yourself.

**Today you can download and validate the code.** Actual cluster creation needs approval; RTF installation needs MuleSoft access and the remaining GitOps integration.



## Which tool does what?

| Tool | Purpose |
|---|---|
| Terraform | Provision the underlying infrastructure |
| Git / GitHub | Review and version the desired configuration |
| Argo CD | Deploy and continuously reconcile the runtime |
| Anypoint | Register/manage RTF and deploy Mule applications once access is available |

UC 1B explicitly requires the manufacturer's chart/operator **through Argo CD**: no manual `kubectl apply` or `helm install`. A Terraform `helm_release` does not replace that workflow. Read-only `kubectl get`, `describe` and `logs` can help verify the result.

## Folders and limits

- `terraform/`: optional, cost-gated Azure AKS infrastructure.
- `runtime-fabric/`: legacy namespace-only bootstrap/reference; direct RTF installation is blocked. **Do not apply it to resources Argo CD will own.**
- `modules/runtime-foundation/`: shared namespace implementation.
- Older `all-sites/`, `runtime-namespaces/` and three-site guides: infrastructure references, not the UC 1B installation path.

See [additional prerequisites and boundaries](Apply-Runtime-Fabric.md). This scope does not install a private management plane, Omni Gateway or Mule applications. Three mocked namespace/guard tests pass; no live vendor chart or RTF installation has been validated. There is no automatic deployment of this RTF proposal.
