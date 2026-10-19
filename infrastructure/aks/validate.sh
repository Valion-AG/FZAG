#!/usr/bin/env bash
# Local/CI validation only. All terraform test providers are mocked.
set -euo pipefail
cd "$(dirname "$0")"
for root in terraform runtime-namespaces; do
  terraform -chdir="$root" fmt -check -recursive
  terraform -chdir="$root" init -backend=false -input=false -lockfile=readonly
  terraform -chdir="$root" validate
  terraform -chdir="$root" test
done
