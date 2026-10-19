# Flughafen Zuerich GitOps demo

Prepared for Argo CD on the existing K3s PoC. This repository is not an OpenShift deployment or an Anypoint management provider.

Only demo ConfigMaps in demo-dev/demo-int/demo-prod are managed initially. Existing Kafka, MQTT, registry, broker secrets and persistent volumes remain outside this application's ownership until an explicit, reviewed adoption is prepared.

## Demo sequence

1. Publish this directory to the selected GitHub repository's main branch. No credentials or passwords belong here.
2. Generate and install Argo CD project/applications with the parent bundle's New-Applications.ps1, after repository read access has been configured.
3. Merge a change to DEV's `release` value. Wait for Argo CD to reconcile it, then verify the ConfigMap.
4. Change that ConfigMap manually in Kubernetes; verify self-healing restores Git's value.
5. Promote the same release through PRs changing INT, then PROD. Configure GitHub branch protection and reviewers separately; YAML does not itself enforce four-eyes approval.
6. Revert the Git commit to roll back. Under self-healing, Git is the desired state; a temporary kubectl edit is not a rollback.
7. To demonstrate deletion, remove a disposable demo ConfigMap in Git and explicitly authorize/prune that deletion in Argo CD. Automated prune is deliberately disabled.

DEV/INT/PROD are namespaces on ONE non-HA Kubernetes node, not three independent platforms. ConfigMaps demonstrate reconciliation, not deployment of MuleSoft APIs or automatic provisioning of portal subscriptions. Those objects require verified supported APIs/provider and authorized Anypoint access.
