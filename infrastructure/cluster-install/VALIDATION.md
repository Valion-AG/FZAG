# Validation

Local checks performed; this installer has not been applied to a Kubernetes cluster.

- Terraform 1.16.6 validate: passed.
- Five mocked Terraform plan tests: foundation defaults, explicit target approval, missing vendor inputs, protected input mounting and MCDP offline confirmation.
- Eight Helm/rendering checks: four namespaces for each site; authorized-worker labels/ConfigMap/Secret/RoleBindings; missing environment-ID rejection; Application target/sync policy; official Argo chart sidecar/volume/environment/ClusterIP rendering; chart lint.
- Official Argo CD chart 10.10.5 fetched and rendered locally. Provider checksums locked for Windows/Linux amd64.
- Linux renderer execution passed in a temporary directory on the existing VM with Helm 4.3.1: shell syntax, all three foundation sites, missing-input rejection, a synthetic vendor chart, checksum mismatch rejection and failure-output isolation. No Kubernetes commands or deployment were executed; temporary files were removed. The actual pinned Argo container execution remains untested.

Not verified: cluster bootstrap, CMP execution, real MuleSoft chart/hook/CRD rendering, activation, supported ingress, application traffic, disconnected MCDP or OpenShift support. Windows sandbox restrictions prevented local Git Bash execution; the renderer was instead exercised on Linux with a synthetic chart. No real vendor chart or credentials were available. These are material integration checks still required before calling the installer end-to-end validated.

No Azure resources were created or modified during these checks.

To repeat offline rendering checks with Bash and Helm installed: `bash tests/render-smoke.sh`. The test uses a temporary copy and fake chart, not real credentials. Run `terraform -chdir=bootstrap init -backend=false` followed by `terraform -chdir=bootstrap test` for the mocked plans.

Template revision: the Azure adapter additionally passes five mocked tests for approval, diagram defaults, platform review, undersized VM rejection and undersized disk rejection. Its candidate baseline is now configurable Dasv5/512 GiB, not the previous F4s/64 GiB proposal. The foundation values schema validates the three site keys and required environment IDs when RTF is enabled. No live infrastructure or runtime installation was performed for this revision.
