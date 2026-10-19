#!/usr/bin/env bash
set -euo pipefail
bundle=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
cp -R "$bundle/charts" "$bundle/renderer" "$bundle/sites" "$scratch/"
cd "$scratch"
bash -n renderer/render.sh
mkdir -p inputs fixture/templates
cat > fixture/Chart.yaml <<'YAML'
apiVersion: v2
name: rtf-agent
version: 0.0.0-mock
YAML
cat > fixture/templates/mock.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: vendor-render-fixture
  namespace: rtf
data:
  activation: {{ required "activation required" .Values.activationData | quote }}
YAML
cat > inputs/vendor-values.yaml <<'YAML'
activationData: MOCK_ONLY_NOT_A_SECRET
muleLicense: MOCK_ONLY_NOT_A_LICENSE
YAML
printf '{"auths":{}}\n' > inputs/registry.json
helm package fixture --destination inputs >/dev/null
mv inputs/rtf-agent-0.0.0-mock.tgz inputs/rtf-agent.tgz
for site in azure zrh mcdp; do
  FZAG_SITE="$site" FZAG_INSTALL_RTF=false bash renderer/render.sh > foundation.yaml
  [ "$(grep -c '^kind: Namespace' foundation.yaml)" = 4 ]
  ! grep -q '^kind: Secret' foundation.yaml
done
if FZAG_SITE=azure FZAG_INSTALL_RTF=true FZAG_INPUTS_DIR="$PWD/missing" bash renderer/render.sh > failed.yaml 2> error.txt; then exit 1; fi
[ ! -s failed.yaml ]
cat > sites/azure/values.yaml <<'YAML'
site: azure
organizationId: MOCK-ORG
stages:
  dev: {environmentId: MOCK-DEV}
  int: {environmentId: MOCK-INT}
  prod: {environmentId: MOCK-PROD}
YAML
printf 'version=0.0.0-mock\nsha256=%s\n' "$(sha256sum inputs/rtf-agent.tgz | cut -d ' ' -f 1)" > sites/azure/vendor-chart.lock
FZAG_SITE=azure FZAG_INSTALL_RTF=true FZAG_INPUTS_DIR="$PWD/inputs" KUBE_VERSION=1.34.0 bash renderer/render.sh > enabled.yaml
grep -q 'name: vendor-render-fixture' enabled.yaml
[ "$(grep -c '^kind: RoleBinding' enabled.yaml)" = 3 ]
[ "$(grep -c '^kind: Namespace' enabled.yaml)" = 4 ]
printf 'version=0.0.0-mock\nsha256=WRONG\n' > sites/azure/vendor-chart.lock
if FZAG_SITE=azure FZAG_INSTALL_RTF=true FZAG_INPUTS_DIR="$PWD/inputs" bash renderer/render.sh > failed.yaml 2> error.txt; then exit 1; fi
[ ! -s failed.yaml ]
grep -q 'checksum differs' error.txt
printf 'version=0.0.0-mock\nsha256=%s\n' "$(sha256sum inputs/rtf-agent.tgz | cut -d ' ' -f 1)" > sites/azure/vendor-chart.lock
printf 'muleLicense: MOCK_ONLY_NOT_A_LICENSE\n' > inputs/vendor-values.yaml
if FZAG_SITE=azure FZAG_INSTALL_RTF=true FZAG_INPUTS_DIR="$PWD/inputs" bash renderer/render.sh > failed.yaml 2> error.txt; then exit 1; fi
[ ! -s failed.yaml ]
grep -q 'Vendor chart rendering failed' error.txt
! grep -q 'MOCK_ONLY_NOT_A_LICENSE' error.txt
printf 'Renderer checks: PASS (syntax, three foundation sites, missing inputs, mock chart rendering, checksum lock, failure output isolation).\n'
helm version --short
