#!/usr/bin/env bash
set -euo pipefail
umask 077
site="${FZAG_SITE:?site missing}"
enabled="${FZAG_INSTALL_RTF:-false}"
case "$site" in azure|zrh|mcdp) ;; *) echo 'Invalid site' >&2; exit 1;; esac
case "$enabled" in true|false) ;; *) echo 'Invalid RTF enable flag' >&2; exit 1;; esac
inputs="${FZAG_INPUTS_DIR:-/var/run/fzag-inputs}"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export HELM_CACHE_HOME="$scratch/cache" HELM_CONFIG_HOME="$scratch/config" HELM_DATA_HOME="$scratch/data"
# Never emit partial manifests if vendor rendering fails. No secret-bearing errors in Argo logs.
args=()
if [ -n "${KUBE_VERSION:-}" ]; then args+=(--kube-version "$KUBE_VERSION"); fi
if [ -n "${KUBE_API_VERSIONS:-}" ]; then
  IFS=',' read -r -a api_versions <<< "$KUBE_API_VERSIONS"
  for api in "${api_versions[@]}"; do args+=(--api-versions "$api"); done
fi
if [ "$enabled" = true ]; then
  for file in vendor-values.yaml registry.json rtf-agent.tgz; do
    [ -s "$inputs/$file" ] || { echo "Missing private RTF input: $file" >&2; exit 1; }
  done
  expected_hash=$(sed -n 's/^sha256=//p' "sites/$site/vendor-chart.lock")
  expected_version=$(sed -n 's/^version=//p' "sites/$site/vendor-chart.lock")
  actual_hash=$(sha256sum "$inputs/rtf-agent.tgz" | cut -d ' ' -f 1)
  [ "$expected_hash" = "$actual_hash" ] || { echo 'Vendor chart checksum differs from Git lock.' >&2; exit 1; }
  actual_version=$(helm show chart "$inputs/rtf-agent.tgz" | sed -n 's/^version: //p' | tr -d '\r"')
  [ "$expected_version" = "$actual_version" ] || { echo 'Vendor chart version differs from Git lock.' >&2; exit 1; }
  helm template runtime-fabric "$inputs/rtf-agent.tgz" --namespace rtf --include-crds \
    -f "$inputs/vendor-values.yaml" -f "sites/$site/rtf-overrides.yaml" "${args[@]}" \
    > "$scratch/vendor.yaml" 2> "$scratch/error" || { echo 'Vendor chart rendering failed; inspect privately, not in Argo logs.' >&2; exit 1; }
fi
foundation_args=()
if [ "$enabled" = true ]; then foundation_args+=(--set-file "registryDockerConfig=$inputs/registry.json"); fi
helm template fzag-foundation charts/foundation -f "sites/$site/values.yaml" \
  --set "rtfEnabled=$enabled" "${foundation_args[@]}" "${args[@]}" \
  > "$scratch/foundation.yaml" 2> "$scratch/error" || { echo 'Foundation rendering failed; check site/environment configuration.' >&2; exit 1; }
cat "$scratch/foundation.yaml"
if [ "$enabled" = true ]; then printf '\n---\n'; cat "$scratch/vendor.yaml"; fi
