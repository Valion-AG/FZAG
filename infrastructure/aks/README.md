# Runtime Fabric: quickstart

**Workflow: Terraform provisions infrastructure -> Git describes the runtime -> Argo CD installs and reconciles it.**

## Current status

The infrastructure proposal was merged in [PR #4](https://github.com/Valion-AG/FZAG/pull/4); merging code does not deploy Runtime Fabric. No new AKS cluster or MuleSoft software has been deployed. A deployable RTF Argo CD Application is still pending MuleSoft access, supported chart/platform selection and protected secret delivery.

## How to use it

1. **Check out the proposal:**

   ```sh
   git clone https://github.com/Valion-AG/FZAG.git
   cd FZAG
   git switch main
   ```

   Open `infrastructure/aks/` for the infrastructure code and this guide.

2. **Choose the target:** Azure, ZRH or MCDP. Each target needs its own supported cluster and configuration. DEV / INT / PROD are stages; they do not automatically mean three clusters per target. ZRH/MCDP hosting is still undecided.

3. **Prepare the cluster:** use the optional `terraform/` AKS infrastructure root for Azure after checking supported Kubernetes versions, permissions, quota and costs and obtaining spending approval. On-premises provisioning depends on the chosen infrastructure. Do not create a cluster using the illustrative version without checking RTF support.

4. **Prepare GitOps and MuleSoft access:** establish the appropriate Argo CD controller and repository/cluster access. Obtain RTF entitlement, activation data, environment IDs and the exact vendor chart version. MCDP needs a verified disconnected/private-control-plane design with internal Git and registry. Agree the bootstrap boundary for the demonstration.

5. **Prepare and review the runtime PR:** add the Argo CD Application for the pinned vendor chart, stage namespaces and required authorizations. Validate secret delivery without placing credentials or licenses in Git. **These deployment artifacts are not ready to execute yet.**

6. **Merge and verify:** Argo CD detects the Git change and installs the runtime. Check Argo sync/health and Anypoint runtime registration. Demonstrate a configuration change, drift correction and supported rollback through Git.

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
