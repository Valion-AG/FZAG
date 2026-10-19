# Runtime Fabric Terraform

**Current entry point: [Apply-Runtime-Fabric.md](Apply-Runtime-Fabric.md).** This bundle is now focused on preparing/installing Runtime Fabric, not Omni Gateway, Crossplane, Anypoint SaaS provisioning or Private Cloud Edition.

| Path | Use |
|---|---|
| `runtime-fabric/` | Main Terraform root: prepare namespaces now, optionally install the official RTF chart later |
| `runtime-fabric/profiles/` | Azure, ZRH and MCDP example inputs |
| `modules/runtime-foundation/` | Shared stage namespace implementation |
| `terraform/` | Optional Azure AKS cluster provisioning; still needs cost approval and refreshed preflight |

Run the RTF root **once per supported cluster**, with a separate working directory/state and explicit kubeconfig/context for each infrastructure. One fabric can use DEV/INT/PROD authorized application namespaces; the Terraform does not deploy Mule applications.

Default: `install_runtime_fabric=false`. This prepares `rtf` and the three worker namespaces without credentials or activated MuleSoft software. Set the flag true only after the documented activation, licensing, platform and networking prerequisites are met. There is no Private Cloud control-plane installation in this root.

ZRH/MCDP cluster hosting remains undecided; their cluster provisioning adapters cannot be completed until that is chosen. The RTF installation path/version must support the actual Kubernetes distribution. Generic/OpenShift namespace compatibility alone is not evidence of RTF product support. MCDP additionally needs approved disconnected RTF/private-control-plane compatibility and local artifact supply.

The Azure AKS candidate remains two F4s v2 nodes in Switzerland North and the existing resource group. No Azure resources were created. Previous estimated extra continuous cost USD 350–390/month is not a new approval; exact patch, quota and cost checks must be refreshed before creation. See [on-demand operation](On-Demand-Betrieb.md) for residual costs when stopped.

The older `runtime-namespaces/`, `all-sites/`, top-level `profiles/` and Three-Sites guide are retained from the broader foundation proposal. **Do not apply those roots to the same resources as `runtime-fabric/`.** Use the RTF-specific guide and profiles for the narrowed scope. Terraform owns the RTF namespace/authorization/Helm installation here; do not add a competing Argo/Helm owner.

Validation: Terraform provider validation and four mocked RTF plan tests pass; seven existing shared-foundation regression tests also pass. No private vendor chart was downloaded or tested. No deployment, license activation, live networking or Mule application test has occurred.

Changes are in draft PR #4, not merged or automatically applied.
