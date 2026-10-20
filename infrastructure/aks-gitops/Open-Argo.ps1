# Run from this original workspace; keep this terminal open.
$workspace = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$env:AZURE_CONFIG_DIR = Join-Path $workspace 'work/azure-config'
$env:KUBECONFIG = Join-Path $workspace 'work/private/aks-preparation/kubeconfig'
$env:PATH = (Join-Path $workspace 'work/tools/kubernetes') + ';' + $env:PATH
Write-Host 'Open http://localhost:18081; user admin. Password: Key Vault kv-fzaginterop261019 / aks-argocd-admin-password.'
& (Join-Path $workspace 'work/tools/kubernetes/kubectl.exe') --context aks-fzag-prep -n argocd port-forward service/argocd-server 18081:80
