# Kubernetes foundation for the supplied FZAG architecture

**Prepared in Terraform, not deployed.** This revision follows your supplied architecture diagram: start with the Kubernetes runtime foundation; connect the MuleSoft control planes later.

## What the code creates

| Terraform root | Purpose |
|---|---|
| `terraform/` | One Azure AKS runtime cluster, `aks-fzag-runtime`, in Switzerland North and existing resource group `flughafen-zürich-poc` |
| `runtime-namespaces/` | DEV / INT / PROD namespaces and initial network isolation on an explicitly selected existing Kubernetes cluster |

The Azure cluster uses two F4s v2 nodes, AKS Free management tier, Entra/Azure RBAC, source-restricted administration, Azure CNI Overlay with Cilium, managed OS disks and normal upgrade surge. It is a PoC foundation, not a production-HA claim.

For `site = "azure"`, the namespace root creates `fzag-azure-dev`, `fzag-azure-int`, `fzag-azure-prod`. It also supports `site = "zrh"` or `"mcdp"` for future application against **separate, already provisioned clusters** with their own contexts and states. Those options do not create on-premises VMs, OpenShift, or a self-hosted MuleSoft control plane. Do not deploy all three sites on the Azure cluster and describe that as the supplied topology.

```text
Now: Terraform -> AKS runtime foundation -> DEV / INT / PROD namespaces

Later: Anypoint SaaS -> Azure and ZRH gateway deployments
       Separate MCDP management -> isolated MCDP gateway deployments
```

## Not included yet

- MuleSoft gateways, Mule Runtime Fabric, Mule applications or Anypoint SaaS organisation/configuration.
- The on-premises ZRH/MCDP cluster infrastructure or MCDP self-hosted control plane. Those require the actual on-prem platform, capacity, network, authorized access and supported MuleSoft artifacts/licensing.
- ExpressRoute, enterprise DNS, ingress certificates, gateway listeners, backend access or SaaS WebSocket connections.
- Argo CD or Crossplane on the new AKS. Existing K3s GitOps stays unchanged. There is no need to install a SaaS management controller merely to create the runtime foundation.
- Nine independent clusters: DEV/INT/PROD are initially logical namespaces; production physical isolation/HA remains a separate design.

The diagram's MCDP isolation also needs clarification before network implementation: it labels MCDP air-gapped while drawing API-traffic arrows toward ZRH. Namespace policies do not establish a network air gap. No MCDP-to-cloud or MCDP-to-ZRH connection is created here.

## Deploy in two phases, after approval

Use Terraform 1.16.6 for the tested local workflow. Choose a currently available exact AKS patch after checking the future gateway compatibility; the example patch is illustrative, not a support claim.

**Phase 1 — Azure cluster**

1. Review `terraform/terraform.tfvars.example` and prepare local inputs (never commit actual tfvars/state/credentials).
2. Recheck Azure permissions/policy, provider registration, SKU availability, costs and quotas. Select a protected/locked state backend before real use.
3. Obtain explicit cost approval, then set `approved_for_billable_creation = true` in the reviewed execution inputs.
4. Run `terraform init`, `terraform plan -out=reviewed.tfplan`, review only the intended new resources, then `terraform apply reviewed.tfplan`.
5. Retrieve an explicit local kubeconfig/context using the cluster-user identity and Entra `kubelogin`. Do not export admin kubeconfig or place credentials in Terraform outputs.

**Phase 2 — Runtime namespaces**

1. Use a different state/backend from Phase 1.
2. Set `kubeconfig_path`, `kube_context`, `site = "azure"`, and `approved_for_cluster_changes = true` after checking the intended cluster.
3. Run init / plan / reviewed apply from `runtime-namespaces/`.
4. Verify three namespaces and `stage-boundary` policies. No gateway applications should be expected yet.

Example credential retrieval after AKS is created, from an authorized PC:

```powershell
az aks get-credentials --subscription 6f5e5d9c-cd3f-4dec-8ade-410c01c8195f --resource-group 'flughafen-zürich-poc' --name aks-fzag-runtime --file ./private-aks-kubeconfig --context fzag-azure-runtime
kubelogin convert-kubeconfig -l azurecli --kubeconfig ./private-aks-kubeconfig
```

Use the actual absolute kubeconfig path in Phase 2. Azure RBAC assignment propagation may take time. Keep this file outside Git. The namespaces root never reads a kubeconfig from cluster Terraform state.

## Initial namespace networking

Policies permit same-namespace pod traffic and DNS to standard Kubernetes CoreDNS in `kube-system` (`k8s-app=kube-dns`), while other pod ingress/egress is denied by default on an enforcing CNI. Gateway ingress, backend egress and future SaaS management endpoints must be explicitly added when their addresses/ports are known. DNS upstreams are not restricted by these pod policies; host traffic and cluster administrators are outside this boundary.

On future OpenShift targets, adapt the DNS policy to the actual OpenShift DNS namespace, labels and service ports before use; the supplied policy defaults are for AKS. Validate enforcement with real test pods before claiming isolation. Terraform mock tests verify configuration shape, not live network behaviour.

## Cost and approval

No creation is authorized yet. At the earlier price check, each F4s v2 Linux node was USD 0.2134/hour: two nodes cost USD 0.4268/hour, or USD 311.56/month at 730 hours. Previous planning envelope: **USD 350–390/month additional** including disks/network/light operations, excluding existing broker VM, tax and MuleSoft licenses. Recheck the estimate before deployment; Cilium capacity and future gateway resources must be evaluated at that time.

Stop after provisioning/testing to avoid ongoing compute when unused. Persistent disk/network/state costs remain: see [on-demand operation](On-Demand-Betrieb.md). No stop schedule has been activated. Free tier is free cluster management, not free nodes or storage.

Previous read-only quota results: regional 2/10 vCPU used, Fsv2 0/10 used. Two nodes add eight vCPU; normal one-node surge requires regional quota at least 14 and family quota at least 12. No quota increase was requested. The F4s v2 SKU listed no regional restrictions; live capacity remains unconfirmed. Exact patch selection and all deployment preflight checks remain pending.

`approved_for_billable_creation` and `approved_for_cluster_changes` default false. Both roots have destruction protection for their principal resources. Neither guard replaces an approval process. No AKS-managed resource group, existing Helm release, broker data or existing K3s resources are modified by these preparations.

## Git, ownership and testing

Code is in draft PR #4 of Valion-AG/FZAG. Nothing auto-applies it. Infrastructure and initial namespaces/network policies are Terraform-owned; future Argo applications should own the gateway workload resources, not compete for these same objects.

The AzureRM 4.59 resource-group validator rejects the umlaut in the existing group name. AKS is therefore created through the official Azure AzAPI provider using the group's exact ARM ID; AzureRM handles identity lookup and scoped role assignment. Existing group name is preserved. API version 2025-04-01 was confirmed in the Azure provider listing.

Local validation uses Terraform init/validate and **mock-provider plan tests**, without Azure resources or Kubernetes calls. Provider lock files include Linux and Windows hashes. `validate.sh` can run the same checks locally or in a future CI workflow; no GitHub Actions workflow or automatic deployment has been activated.

Remaining post-deployment tests: real Azure plan/apply, nodes Ready, Entra login, DNS, network-policy enforcement, stop/start recovery, and later actual gateway installation/connectivity. The code does not claim those tests have already passed.
