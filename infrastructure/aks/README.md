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

Once those are ready, your workflow is:

1. Open a GitHub pull request: for example, “Install Runtime Fabric in Azure.”
2. Review and merge it.
3. Open Argo CD and wait for **Synced** and **Healthy**.
4. Open Anypoint Runtime Manager and check that the fabric is registered and connected.

**The RTF Argo CD Application is not ready to execute yet.** Argo CD also needs repository and target-cluster access. These are the intended steps once that integration is completed.

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
