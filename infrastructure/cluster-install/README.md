# Reusable cluster installer

Use this **after an empty Kubernetes cluster exists**. One bootstrap installs Argo CD, its RTF renderer and a site Application. Argo CD then creates `rtf` plus DEV/INT/PROD worker namespaces and, when enabled, reconciles the official RTF chart. Repeat with a different kubeconfig, site profile and private state for each cluster.

## Quickstart: foundation without MuleSoft access

Requirements: Terraform >=1.9, an authorized kubeconfig/context, cluster-admin permissions, sufficient cluster capacity and access to the configured chart/image/Git sources. This bootstrap is for an empty cluster, not an existing Argo CD installation. Do not apply alongside the older namespace Terraform roots.

From `infrastructure/cluster-install` in your checkout (PowerShell):

```powershell
$PrivateDir = Join-Path $env:LOCALAPPDATA 'FZAG/azure-cluster-01'
New-Item -ItemType Directory -Force $PrivateDir | Out-Null
Copy-Item profiles/azure.tfvars.example "$PrivateDir/cluster.tfvars"
```

Edit that private file: specify the existing cluster's absolute kubeconfig path and exact context, set `approved_for_cluster_changes = true` after review, and leave `install_rtf = false`.

```powershell
terraform -chdir=bootstrap init -backend-config="path=$PrivateDir/bootstrap.tfstate"
terraform -chdir=bootstrap plan -var-file="$PrivateDir/cluster.tfvars" -out="$PrivateDir/bootstrap.tfplan"
terraform -chdir=bootstrap apply "$PrivateDir/bootstrap.tfplan"
```

These commands change the selected cluster; they do not provision AKS or create an Anypoint account. Argo CD sync happens asynchronously after Terraform finishes. Its server is ClusterIP; no public load balancer is requested. Existing capacity is consumed and underlying infrastructure costs continue.

Verify with the **same kubeconfig/context**:

```powershell
kubectl --kubeconfig C:/PRIVATE/azure/kubeconfig --context YOUR_CONTEXT -n argocd get applications
kubectl --kubeconfig C:/PRIVATE/azure/kubeconfig --context YOUR_CONTEXT get namespaces rtf fzag-azure-dev fzag-azure-int fzag-azure-prod
kubectl --kubeconfig C:/PRIVATE/azure/kubeconfig --context YOUR_CONTEXT -n argocd port-forward service/argocd-server 8443:443
```

Open https://localhost:8443 to inspect Argo sync/health (self-signed TLS by default). The initial `admin` password is in `argocd-initial-admin-secret` in `argocd`; read it locally using your authorized Kubernetes tooling and change it. Never commit it. The namespace stages are placeholders until associated with real Anypoint environments.

## Enable the official RTF installation later

You do not need application connectivity between sites. You **do** need vendor chart/image access and activation inputs to install actual RTF. Registration/readiness and later management require the appropriate control-plane connectivity.

1. Confirm the actual Kubernetes distribution/version, sizing, ingress and selected chart support with MuleSoft. Generic Kubernetes namespace portability does not imply RTF support on every distribution. For OpenShift, confirm the supported operator/installation track; this bundle implements the Helm track only.
2. Obtain the exact vendor chart and Runtime Manager-generated values for this fabric. Save private files outside the repository:

   ```text
   C:/PRIVATE/azure/rtf-inputs/
     rtf-agent.tgz       # exact unmodified vendor Helm chart archive
     vendor-values.yaml # real activation/license and vendor settings
     registry.json      # valid Docker registry authentication config
   ```

   For example, `helm pull rtf/rtf-agent --version <VERSION_FROM_RUNTIME_MANAGER>` downloads the chart after you configure authenticated vendor repository access; rename the archive to `rtf-agent.tgz`. Do not download or publish vendor artifacts without the required access/entitlement. Keep this bundle below Kubernetes Secret size limits (1 MiB decoded data per Secret); a larger chart needs a protected artifact fetch/mount adapter instead.
3. Fill real organization/environment IDs into `sites/<site>/values.yaml`, review `rtf-overrides.yaml`, and set the exact chart `version` and archive `sha256` in `sites/<site>/vendor-chart.lock`. Obtain the checksum locally, for example `(Get-FileHash C:/PRIVATE/azure/rtf-inputs/rtf-agent.tgz -Algorithm SHA256).Hash.ToLower()`. Commit only this nonsecret configuration. The renderer rejects a chart that does not match the Git lock. Never put activation/license or registry credentials in Git.
4. Set in your private Terraform inputs:

   ```hcl
   install_rtf = true
   vendor_support_confirmed = true
   private_inputs_directory = "C:/PRIVATE/azure/rtf-inputs"
   ```

5. Re-run the saved-plan workflow above. Terraform mounts the private inputs into the renderer; **Argo CD renders and applies the vendor chart**, not a Terraform RTF Helm release. Check Argo resources, then Anypoint registration. Without control-plane reachability some RTF components can remain unready; installing manifests is not proof of a working fabric.

The renderer uses the vendor chart unchanged and overlays the authorized-namespace configuration. Vendor hook/CRD behavior and rendered resource ownership must be validated against the actual selected chart before a real installation. There is no fabricated license bypass or fake working runtime.

## Reuse for another cluster

Use a separate working copy/private backend for every cluster. Copy the ZRH/MCDP profile, specify its kubeconfig/context, and run the same workflow. One local Argo CD instance manages its own cluster (`https://kubernetes.default.svc`); changing the kubeconfig selects the bootstrap target. There is no central cross-cluster connection required by this layout.

For MCDP, mirror Git, charts and **all** images internally and configure the corresponding inputs. RTF additionally requires `mcdp_offline_support_confirmed = true`. This flag records an operator's confirmation; it does not make an unsupported disconnected deployment work. No self-hosted Anypoint management plane is installed. Existing OpenShift GitOps installations should use a separately reviewed integration rather than this new-Argo bootstrap.

## Ownership, updates and scope

- Terraform owns bootstrap Argo CD, the plugin/private input Secret, AppProject and root Application. Argo CD owns the stage namespaces, authorizations and RTF resources. No manual `kubectl apply` or `helm install` is used for RTF. The tender bootstrap boundary still needs agreement; this is not a claim that Terraform bootstrap is explicitly exempted.
- Site configuration changes flow through Git. To update the pinned vendor release, update `vendor-chart.lock` in Git, replace the private chart/values deliberately and re-plan/apply bootstrap. Coordinate the two changes: a temporary lock/archive mismatch blocks rendering rather than applying an unapproved chart. Private input changes require an Argo **Hard Refresh** to invalidate the manifest cache. Do not disable RTF as an uninstall procedure: pruning is disabled and existing resources remain. Follow a reviewed vendor upgrade/rollback procedure, including CRD/hook requirements. Later changes to authorized namespaces can require an agent restart; use the vendor procedure and a reviewed GitOps rollout mechanism.
- Private data exists in Terraform state and in Argo's rendered-manifest cache. Restrict state storage and Argo access; protect Kubernetes Secrets. Only trusted administrators should modify this installer and repository.
- This installs the GitOps/runtime foundation and optionally RTF. It does not install an Anypoint management plane, ingress controller, application deployments, Kafka/MQTT, ExpressRoute, persistence gateway or clustered-app extras. Supply the supported ingress/platform prerequisites before enabling RTF. No network-policy isolation is claimed merely by creating namespaces.

Validation is recorded in `VALIDATION.md`. No existing Azure resources are changed by publishing this bundle.

References: [MuleSoft Helm installation](https://docs.mulesoft.com/runtime-fabric/latest/install-helm), [Argo CD CMP](https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/).
