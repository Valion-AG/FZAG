# AKS + Git — prepared, NOT deployed

19 October 2026. Existing broker VM and existing K3s Argo CD are unchanged. No additional billable resource was created.

## Why this exists

UC 1A requires declarative management of the SaaS objects, including continuous drift correction without manually starting a pipeline. MuleSoft has the official `mulesoft/anypoint` Terraform provider. Terraform CLI can provision supported objects through the Anypoint API from outside MuleSoft; MuleSoft does not have to run inside AKS.

Proposed path: Git -> Argo CD -> Crossplane Terraform Workspace -> official MuleSoft Terraform provider -> Anypoint SaaS. It still needs a tested resource coverage matrix, controller/provider/CLI compatibility, protected persistent Terraform state, scoped Connected App credentials and a real Anypoint drift test. The Crossplane Terraform provider is a community component; vendor support for that complete chain must not be assumed.

UC 1B makes AKS conditional if Azure gateways are not supplied as SaaS. OpenShift remains explicitly required for the specified on-prem locations; an AKS demo does not satisfy that OpenShift requirement. AKS is a useful customer-managed platform demonstration, not a prerequisite for using Terraform with cloud Anypoint.

## Proposed resources

- New AKS `aks-fzag-gitops` in the existing resource group and Switzerland North.
- AKS-owned infrastructure group `rg-fzag-aks-gitops-nodes`; AKS creates/manages its node infrastructure there. Do not manually delete it.
- Free management tier; two `Standard_F4s_v2` Linux system nodes, each 4 vCPU / 8 GiB, 64-GiB managed OS disk.
- Standard load balancer/outbound public IP, Azure CNI overlay, source-restricted Kubernetes API, Entra/Azure RBAC, local accounts disabled.
- After approval: install pinned Argo CD and Crossplane/provider versions, configure durable secret-protected state and authorized Anypoint demo credentials, then demonstrate a small real Anypoint object and drift repair.
- Existing Kafka/MQTT/Registry remain on the existing VM; no data migration and no second set of brokers planned.

## Permissions, quotas, versions

Azure read checks confirm active target subscription and a permission entry with `actions: ["*"]`, no exclusions. This does not override policy, capacity or MFA gates.

Current regional quota: 2 / 10 vCPU used. Two F4 nodes consume the remaining 8. Fsv2 family quota: 0 / 10 used. Rolling upgrades with one surge node require another 4 vCPU: recommend regional quota at least 14 and Fsv2-family quota at least 12. No quota request was submitted. Deployment must wait for quota headroom or an explicitly reviewed no-surge maintenance strategy; the template retains normal surge behaviour.

AKS API reports default minor 1.36. Exact patch and Crossplane/provider compatibility must be selected before plan/apply. Standard_F4s_v2 lists no regional restrictions; actual live allocation capacity is only known on deployment. Microsoft.ContainerService is registered; other required providers/policy still need confirmation. AzureRM provider auto-registration is disabled in the template to avoid unexpected subscription changes.

## Estimated incremental cost

Azure Retail Prices API: Switzerland North, Linux Virtual Machines FSv2 Series, F4s v2, consumption, USD 0.2134/hour per node. Filter out HDInsight, Windows, Spot and Low Priority meters.

2 x 730 x USD 0.2134 = **USD 311.56/month for node compute**. Allow **USD 350–390/month additional** including OS disks, load balancer/IP and light operating traffic/logging. Not a quote or cap; excludes taxes, exchange rates, MuleSoft licensing, optional paid plans and unusually high traffic. The existing PoC's original USD 60–75/month envelope remains separate: combined planning envelope approximately USD 410–465/month.

The AKS Free tier does not make node VMs, disks and network resources free. Approval is required before creating them. If the candidate SKU cannot be allocated, stop and re-estimate rather than silently choosing a larger one.

## Code and release process

`terraform/main.tf` addresses the existing resource group by its exact ARM ID, creates only the new AKS and scoped administrator assignment, and blocks planning/apply until `approved_for_billable_creation=true`. `prevent_destroy` protects the cluster from an unreviewed Terraform destroy. Do not remove this guard for routine operations.

AzureRM 4.59 rejects the umlaut in this existing resource-group name during its local name validation. The prepared configuration therefore uses the official Azure AzAPI provider to create AKS under the exact existing group ID, and AzureRM for identity lookup/role assignment. It does not rename the group or work around the issue by creating the cluster elsewhere. API version 2025-04-01 is listed by the subscription's ContainerService provider.

Code is prepared locally for review. Before publication/deployment: add it to a review branch of Valion-AG/FZAG, verify the plan contains no changes to existing resources, agree on an encrypted/locked state backend, and obtain explicit cost approval. Do not put state, credentials, plans containing secrets, kubeconfigs or tfvars with secrets in the public repository. A CI pipeline can fmt/validate/plan, but that alone is not continuous SaaS drift correction.

## Validation gates

1. User approves additional costs; permission/policy/provider/SKU/quota/version checks pass.
2. Terraform plan: only new intended AKS resources; review before apply.
3. AKS nodes Ready, administration source restriction and Entra RBAC validated.
4. Argo CD synchronizes a harmless namespace/configuration from Git.
5. Crossplane/provider compatible and healthy; state durability and secret access validated.
6. Connected App granted least required scopes; Terraform controls a dedicated Anypoint test object.
7. Change that object in Anypoint UI; controller detects and reverses it without manual pipeline or refresh.
8. Demonstrate Git promotion and rollback, document covered resource types and support ownership.

Until gates 6–8 pass, do not claim Anypoint GitOps coverage.

## Sources

- https://docs.mulesoft.com/mulesoft-terraform-provider/install-configure
- https://docs.mulesoft.com/mulesoft-terraform-provider/resources
- https://github.com/crossplane-contrib/provider-terraform
- https://learn.microsoft.com/en-us/azure/aks/use-system-pools
- https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices
