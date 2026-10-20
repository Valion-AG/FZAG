terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  backend "local" {}
  required_providers {
    helm = { source = "hashicorp/helm", version = "= 3.3.0" }
  }
}
variable "kubeconfig_path" { type = string }
provider "helm" {
  kubernetes = {
    config_path    = var.kubeconfig_path
    config_context = "aks-fzag-prep"
  }
}
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.10.5"
  timeout          = 600
  wait             = true
  values = [yamlencode({
    crds = { install = true }
    configs = {
      params = { "server.insecure" = true }
      cm     = { "timeout.reconciliation" = "30s" }
    }
    server        = { service = { type = "ClusterIP" } }
    dex           = { enabled = false }
    notifications = { enabled = false }
  })]
}
resource "helm_release" "gitops_root" {
  name       = "fzag-aks-gitops"
  namespace  = "argocd"
  chart      = "${path.module}/../bootstrap-chart"
  depends_on = [helm_release.argocd]
}
