# Runtime Fabric infrastructure and GitOps proposal

Start with [the quickstart](Apply-Runtime-Fabric.md).

**UC 1B requires installation through Argo CD using the manufacturer's chart/operator.** No manual `kubectl apply` or `helm install`; a Terraform Helm release does not demonstrate this workflow either.

Terraform prepares infrastructure. Git defines the runtime configuration; Argo CD deploys and reconciles it. The previous direct Terraform RTF installation has been removed. `runtime-fabric/` remains a namespace-only bootstrap/reference root, not the tender installation path. Do not co-own its namespaces with Argo CD.

The actual RTF Argo Application remains pending entitlement, supported chart/platform selection and verified protected secret delivery. No MuleSoft software or new AKS cluster has been deployed. Azure provisioning remains subject to fresh quota/cost checks and spending approval. On-premises hosting remains undecided.

The older `all-sites/`, `runtime-namespaces/` and three-site guides are infrastructure references, not proof of UC 1B compliance. No management plane, Omni Gateway or Mule application is installed by this proposal.

Validation: three mocked namespace/guard tests; no live RTF installation or vendor chart validation. Draft PR #4 is not merged or automatically applied.
