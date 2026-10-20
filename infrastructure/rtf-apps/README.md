# Change Mule application replicas through Git

Git → Argo CD → MuleApplication CR → Anypoint Controller → Mule application replicas.

This package manages Mule **application** replicas and CPU/memory. It does not scale the AKS node pool, RTF agent or Flex/Omni Gateway. Secrets stay outside Git.

## One-time activation

1. Verify the installed Helm-based RTF version supports Anypoint Controller (vendor guide specifies RTF 3.0.1). Use a supported Mule runtime patch released on/after 7 November 2025. Do not upgrade RTF or adopt an existing application without reviewing its state.
2. Merge `argocd/rtf-controller-values.yaml` into the existing vendor RTF chart configuration, preserving private activation/license/registry inputs. Reconcile the vendor release through the cluster installation GitOps path. This overlay is not a complete RTF install.
3. Create the Anypoint Connected App and supply the `anypoint-credentials` Secret privately in the actual RTF namespace, with `ANYPOINT_CLIENT_ID` and `ANYPOINT_CLIENT_SECRET`. Required scopes: Exchange Viewer, Profile, Create Applications, Delete Applications, Read Runtime Fabrics, scoped to the appropriate business group/environment. These are Anypoint credentials, not the Entra SSO/Postman registration.
4. Publish the Mule application artifact to Exchange. Fill in actual target, business group, runtime, artifact coordinates and environment in `values.yaml`, following `examples/dev.values.yaml`. Set `enabled: true` only when ready. The namespace label must match the real RTF installation namespace; `mulesoft` is the preparation default, not a discovered release namespace.
5. Bootstrap Argo CD on AKS (or register AKS with the central Argo CD instance). Add `argocd/application.yaml.example` through the infrastructure bootstrap. For central Argo CD change destination to the registered AKS cluster; never apply the in-cluster example to the broker VM's Argo CD unchanged. The example file is not automatically picked up by existing applications.

## Daily use: change replicas

In GitHub, edit `infrastructure/rtf-apps/values.yaml`:

```yaml
stages:
  dev:
    # Keep namespace, environment and application artifact fields unchanged.
    applications:
      - name: flights-api
        # Keep artifact and resources fields unchanged.
        replicas: 2  # Change 1 → 2
```

Save/commit the change to main. Argo CD reconciles the CR and Anypoint Controller reconciles the application. Change back to `replicas: 1` to scale down. Edit the same application's `resources.requests` and `resources.limits` to change CPU/memory. Preserve the rest of the application entry when editing.

Observe Argo CD sync and the MuleApplication desired/ready status. Runtime Manager displays controller-managed apps read-only. Argo CD Synced alone is not proof that Mule replicas are healthy. Two replicas on one node do not prove node-level HA; verify placement and available capacity before the HA demonstration.

The example enables self-healing but not automatic pruning. Deleting an application from Git therefore does not delete it until a reviewed prune/sync is requested. Do not toggle `enabled` off as a deletion mechanism. Existing Runtime Manager-created apps need reviewed redeployment as CRs; do not have two controllers fight over their Kubernetes Deployments.

## Current status

Template prepared; no real Mule app deployed by this package. Live prerequisites, the actual RTF chart version and private credentials must be checked against the running target. Helm rendering checks do not establish vendor CRD admission or end-to-end deployment.

[Vendor Anypoint Controller guide](https://docs.mulesoft.com/runtime-fabric/latest/deploy-mule-app-anypoint-controller)
