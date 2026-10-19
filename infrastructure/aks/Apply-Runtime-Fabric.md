> Superseded entry point: use the [reusable cluster installer](../cluster-install/README.md). The text below describes the earlier proposal and is retained for context; its pending-artifact statements predate the new installer. The new bundle still requires live cluster and real vendor-chart validation.

# Runtime Fabric: GitOps quickstart



Draft [PR #4](https://github.com/Valion-AG/FZAG/pull/4); no new AKS or RTF deployment has occurred.



## Tender requirement



UC 1B requires the manufacturer's operator or Helm chart to be deployed and reconciled **through Argo CD**. It explicitly says: **Kein «kubectl apply» und kein «helm install» von Hand.** A Terraform `helm_release` is not a substitute for this demonstration. The direct Terraform RTF installation has therefore been removed and its old enable flag is rejected.



## Intended workflow



1. **Prepare infrastructure:** Terraform provisions the approved AKS infrastructure, or use the eventual supported on-premises cluster. Confirm exact RTF/platform compatibility, quota and costs first. No new billable infrastructure is approved yet.

2. **Establish GitOps:** have Argo CD and its repository/cluster access ready. The tender does not explicitly exempt bootstrap actions; agree and document this boundary before the demonstration. MCDP needs internal Git, registry and an internal controller for disconnected operation.

3. **Prepare the RTF Git change:** after entitlement and control-plane access are available, pin the official chart version and configure an Argo CD Application. Store stage namespaces, required authorizations and nonsecret chart configuration in Git. Obtain real org/environment IDs and activation data from the intended Anypoint control plane.

4. **Resolve secret delivery:** provide activation/license, image-pull and chart repository credentials through an approved protected integration. Do not commit them or invent unsupported chart secret fields. The exact chart and Argo rendering/secret mechanism still need validation; no runnable RTF Application is supplied yet.

5. **Review and merge the PR:** Argo CD observes Git and installs/reconciles the vendor chart and associated resources. Updates and rollback use Git changes. Keep one owner per resource.

6. **Demonstrate:** show Git commit, Argo sync and health, resulting runtime registration and stage association. Show a controlled drift correction and a supported version change/rollback. Read-only `kubectl get`, `describe` and `logs` are useful for verification; they do not replace GitOps installation.



Repeat with separate configuration for Azure, ZRH and MCDP. DEV/INT/PROD are stages inside each intended runtime environment; they do not automatically require three independent infrastructure clusters per site.



## What the existing Terraform folders do



- `terraform/`: optional Azure AKS provisioning, still gated by approval and fresh preflight. The illustrative Kubernetes version must be checked against RTF support before creating a cluster.

- `runtime-fabric/`: **legacy namespace-only bootstrap/reference**, not the UC 1B installation path. It contains no Helm release, credentials, activation or MuleSoft installation. Do not apply it to namespaces that Argo CD will own. For the tender workflow, put namespace definitions and authorizations in Git under Argo CD instead.

- `runtime-fabric/profiles/`: example site/context inputs for that legacy namespace preparation, not an RTF deployment command.



## Pending prerequisites



Anypoint access and appropriate entitlement; exact supported RTF chart/platform versions; actual ZRH/MCDP hosting; verified MCDP private-control-plane/offline compatibility; ingress/network design; protected secrets integration; the validated Argo CD Application and installation test. Generic Kubernetes/OpenShift namespace support does not establish MuleSoft product support. The existing small K3s broker VM must not be assumed to be a supported RTF target.



This scope prepares Runtime Fabric integration. It does not install the isolated management plane or fulfill the other UC 1B components by itself.

