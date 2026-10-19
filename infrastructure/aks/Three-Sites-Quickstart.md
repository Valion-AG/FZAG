# Same Kubernetes foundation, three infrastructures

**Prepared code only; no infrastructure deployed.** ZRH/MCDP hosting is still undecided. Kubernetes/OpenShift hosting and MuleSoft software are separate layers.

```text
Infrastructure provisioning adapters
  Azure -> AKS Terraform adapter provided
  ZRH   -> select hosting, then add its provisioning adapter
  MCDP  -> select hosting, then add its provisioning adapter
                         |
             same runtime-foundation module
                         |
  Azure cluster: DEV / INT / PROD; future cloud-managed runtimes
  ZRH cluster:   DEV / INT / PROD; future cloud-managed runtimes
  MCDP cluster:  DEV / INT / PROD + empty local-management namespace
```

## What is reusable now?

| Directory | Purpose |
|---|---|
| `modules/runtime-foundation/` | Shared stage namespaces, labels and initial network policies |
| `runtime-namespaces/` | Apply the shared module to one explicitly selected cluster |
| `profiles/` | Azure, ZRH and MCDP example inputs |
| `all-sites/` | Connected-lab orchestration of three existing, distinct clusters |
| `terraform/` | Azure-only AKS cluster provisioning |

The common module supports AKS, OpenShift and generic Kubernetes profiles. AKS/generic defaults use CoreDNS in `kube-system` on port 53. OpenShift defaults use `openshift-dns`, its DNS daemonset label and port 5353. `dns_override` adapts this to the actual platform. Validate live CNI enforcement and DNS; mocks do not prove platform certification.

## Normal deployment: one execution per site

1. Provision the cluster using the appropriate infrastructure adapter. Only the Azure adapter exists so far.
2. Configure an authorized kubeconfig/context and a protected **separate Terraform state per site**.
3. Copy the matching example from `profiles/` to a private local inputs file and replace the kubeconfig/context. Select the actual platform profile; OpenShift is a preset, not a decision already made about your hosting.
4. Review the target, then enable `approved_for_cluster_changes` after authorization.
5. From `runtime-namespaces/`, run init, plan, review and apply using those private inputs. Do not run apply as part of validation.
6. Repeat against the other infrastructure. For MCDP, execute from **inside MCDP** using the offline procedure below.

The same module must not be owned simultaneously by `all-sites/` and individual single-site states. Choose one ownership model for a lab. Do not apply two Terraform roots to the same namespaces.

MCDP enforces the `local` management intent and reserves `fzag-mcdp-management`. This is an empty namespace, not an installed control plane. The eventual official installer may require a different namespace/topology; adapt the foundation to that supported installation procedure.

## Connected test lab only

`all-sites/` uses three explicit provider aliases/kubeconfigs. It checks the UID of `kube-system` on each target and rejects duplicate cluster identities, preventing three contexts pointing to one cluster from being presented as three infrastructures.

Set `connected_lab_mode=true` only for a connected test lab and supply all three existing cluster targets. This root creates nine stage namespaces and the one empty MCDP-management namespace. It provisions no on-prem VMs, no OpenShift clusters and no MuleSoft products. **Do not use this connected root to claim real MCDP airgap.**

## True air-gapped MCDP

Reuse the same `runtime-namespaces/` root and `modules/` code inside the isolated environment. Keep its state, Kubernetes credentials, logs, DNS and installation inputs local. No SaaS credentials are part of this foundation.

Before transfer, obtain the Terraform executable, provider lock file and the signed Kubernetes-provider packages for the actual offline operating system. For example, on an authorized connected preparation host after init:

```sh
terraform -chdir=runtime-namespaces providers mirror -platform=linux_amd64 /ABSOLUTE/PATH/provider-mirror
```

Transfer the provider mirror, local module source tree, lock file and executable through the approved offline transfer process. Configure the Terraform CLI inside MCDP with a local mirror and no direct registry fallback:

```hcl
provider_installation {
  filesystem_mirror {
    path    = "/approved/provider-mirror"
    include = ["registry.terraform.io/hashicorp/kubernetes"]
  }
}
```

Then initialize with the locked provider using `terraform init -lockfile=readonly`, review the plan and apply locally after approval. This offline procedure is prepared, not yet executed. An internet-connected GitHub/Argo controller must not manage a true air-gapped MCDP environment. Local Git/registry/automation and offline MuleSoft artifacts must be planned separately.

Initial network policies allow same-namespace pod traffic and the selected DNS service; other pod ingress/egress is denied on an enforcing CNI. Gateway ingress, local control-plane communication, backend access and approved cloud endpoints are not opened yet. DNS forwarding, node/host networking and cluster-admin privileges are outside these policies; this is not proof of a physical air gap.

## What can be prepared before MuleSoft licensing?

We can prepare Kubernetes infrastructure, namespaces, networking, Terraform, Git layout, installation input templates, schemas and test services without installing MuleSoft. Exact product/version selection remains necessary before final sizing and chart configuration.

| Product in your architecture | Needed before real setup/use |
|---|---|
| Runtime Fabric for Mule applications | Anypoint organisation, Runtime Fabric activation/installation access and appropriate Mule runtime entitlement/license; the install procedure obtains activation data from Anypoint |
| Omni/Flex Gateway | Supported image/chart and platform registration credentials/data; Local Mode is not an automatic registration-free installation |
| Private Cloud Edition for MCDP management | Supported installation package, license/access and verified disconnected-operation procedure |

This does not mean you must buy a production license before all preparation: MuleSoft may provide a suitable evaluation/partner/demo entitlement. We have none available yet, so no activated MuleSoft deployment is included. No registration data, private license material or product credentials belong in the public repository.

The referenced PCE 4.x prerequisites list **32 vCPUs and 128 GiB total cluster memory** as minimum resources. The small Azure runtime PoC is not a substitute for that self-hosted control-plane platform. Confirm the exact offered version, support and offline requirements with MuleSoft before provisioning MCDP capacity.

## Validation

Local provider validation and mocked plan tests cover namespace naming for all sites, OpenShift DNS, rejection of cloud-managed MCDP, three-cluster identity checks and the Azure approval/settings checks. No real cluster provisioning, live policy enforcement, offline install or MuleSoft license activation has been demonstrated by these tests.

Sources:

- https://docs.mulesoft.com/runtime-fabric/latest/install-helm
- https://docs.mulesoft.com/gateway/1.9/flex-local-reg-run
- https://docs.mulesoft.com/private-cloud/latest/install-checklist
- https://access.redhat.com/solutions/3804501
