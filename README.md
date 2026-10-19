# Flughafen Zuerich GitOps demo

Prepared for Argo CD on the existing K3s PoC. This repository is not an OpenShift deployment or an Anypoint management provider.

Argo CD manages demo ConfigMaps in demo-dev/demo-int/demo-prod, plus the existing Kafka 4.3, Kafka 4.1, MQTT and Schema Registry workload/service specifications in interop. The broker adoption was reviewed against the running cluster and did not replace broker pods. Broker secrets and persistent volumes remain outside application ownership. Automatic pruning is disabled.

## Demo sequence

1. The selected GitHub repository is Valion-AG/FZAG, branch main. No credentials or passwords belong here.
2. Bootstrap projects/applications are in bootstrap/. The existing VM runs Argo CD v3.5.5, chart 10.10.5, with values in platform/argocd-values.yaml.
3. Merge a change to DEV's `release` value. Wait for Argo CD to reconcile it, then verify the ConfigMap.
4. Change that ConfigMap manually in Kubernetes; verify self-healing restores Git's value.
5. Promote the same release through PRs changing INT, then PROD. Configure GitHub branch protection and reviewers separately; YAML does not itself enforce four-eyes approval.
6. Revert the Git commit to roll back. Under self-healing, Git is the desired state; a temporary kubectl edit is not a rollback.
7. To demonstrate deletion, remove a disposable demo ConfigMap in Git and explicitly authorize/prune that deletion in Argo CD. Automated prune is deliberately disabled.

DEV/INT/PROD are namespaces on ONE non-HA Kubernetes node, not three independent platforms. ConfigMaps demonstrate reconciliation, not deployment of MuleSoft APIs or automatic provisioning of portal subscriptions. Those objects require verified supported APIs/provider and authorized Anypoint access.

## Workload ownership and recovery

Changes to adopted workload/service specifications go through Git and Argo CD. Do not run parallel Helm upgrades of the old interop/interop-extensions releases: Helm release history remains but Helm is no longer their active configuration writer. Do not uninstall these Helm releases, because that would delete live workloads and could affect persistent claims. Kafbat remains a Docker container outside Argo ownership.

Only Service, Deployment and StatefulSet are allowed in the broker Argo project; Secrets, PVCs, PersistentVolumes and Azure resources are excluded. A rebuild therefore also needs the existing separately secured bootstrap, storage and secret provisioning. This is not a complete disaster-recovery or air-gap implementation.

The PR promotion demo changes only release metadata in ConfigMaps. It uses one operator to create and merge PRs; independent review and branch protection are not claimed. Current applications track main, with selfHeal enabled and prune disabled.

## Runtime Fabric quickstart

Start with [the Runtime Fabric quickstart](infrastructure/aks/README.md) for the Terraform infrastructure and Argo CD workflow. Runtime Fabric is not deployed; MuleSoft access and deployment integration remain pending.
