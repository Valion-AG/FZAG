terraform {
  backend "local" {}
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "= 3.3.0" }
    helm       = { source = "hashicorp/helm", version = "= 3.3.0" }
  }
}
variable "site" {
  type = string
  validation {
    condition     = contains(["azure", "zrh", "mcdp"], var.site)
    error_message = "Select azure, zrh or mcdp."
  }
}
variable "platform" {
  type = string
}
variable "kubeconfig_path" {
  type = string
}
variable "kube_context" {
  type = string
  validation {
    condition     = length(trimspace(var.kube_context)) > 0
    error_message = "Specify the intended cluster context."
  }
}
variable "approved_for_cluster_changes" {
  type    = bool
  default = false
}
variable "install_runtime_fabric" {
  description = "False prepares namespaces only. True enables the licensed Helm installation."
  type        = bool
  default     = false
  validation {
    condition     = !var.install_runtime_fabric || (var.entitlements_confirmed && var.platform_support_confirmed && var.network_reviewed)
    error_message = "Confirm entitlement/activation access, exact supported platform/version and RTF network/ingress prerequisites first."
  }
  validation {
    condition     = !var.install_runtime_fabric || (var.organization_id != null && toset(keys(var.environment_ids)) == toset(["dev", "int", "prod"]))
    error_message = "Supply organisation ID and all three real environment IDs from the intended control plane."
  }
  validation {
    condition     = !var.install_runtime_fabric || (var.chart_version != null && (var.values_file != null ? fileexists(var.values_file) : false) && (var.registry_config_file != null ? fileexists(var.registry_config_file) : false))
    error_message = "Provide an exact UI-approved chart version, private Runtime Manager values file and private registry Docker config JSON."
  }
  validation {
    condition     = !var.install_runtime_fabric || (var.chart_archive != null ? fileexists(var.chart_archive) : var.chart_repository != null)
    error_message = "Provide either a local chart archive or the authenticated vendor chart repository."
  }
  validation {
    condition     = !var.install_runtime_fabric || var.site != "mcdp" || (var.mcdp_offline_support_confirmed && var.chart_archive != null && var.chart_repository == null)
    error_message = "MCDP installation requires vendor-confirmed offline support and a local chart/archive, not an online chart repository."
  }
}
variable "entitlements_confirmed" {
  type    = bool
  default = false
}
variable "platform_support_confirmed" {
  type    = bool
  default = false
}
variable "network_reviewed" {
  type    = bool
  default = false
}
variable "mcdp_offline_support_confirmed" {
  type    = bool
  default = false
}
variable "organization_id" {
  type    = string
  default = null
}
variable "environment_ids" {
  type    = map(string)
  default = {}
}
variable "chart_version" {
  type    = string
  default = null
}
variable "chart_repository" {
  type    = string
  default = null
}
variable "chart_archive" {
  type    = string
  default = null
}
variable "repository_username" {
  type      = string
  default   = null
  sensitive = true
}
variable "repository_password" {
  type      = string
  default   = null
  sensitive = true
}
variable "values_file" {
  type    = string
  default = null
}
variable "registry_config_file" {
  type    = string
  default = null
}

provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig_path)
  config_context = var.kube_context
}
provider "helm" {
  kubernetes = {
    config_path    = pathexpand(var.kubeconfig_path)
    config_context = var.kube_context
  }
}
resource "kubernetes_namespace_v1" "rtf" {
  metadata { name = "rtf" }
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.approved_for_cluster_changes
      error_message = "Approve changes to the exact target cluster before preparation."
    }
  }
}
locals {
  worker_labels = var.install_runtime_fabric ? {
    for stage in ["dev", "int", "prod"] : stage => {
      "rtf.mulesoft.com/agentNamespace" = "rtf"
      "rtf.mulesoft.com/envId"          = lookup(var.environment_ids, stage, "")
      "rtf.mulesoft.com/org"            = var.organization_id
      "rtf.mulesoft.com/role"           = "workers"
    }
  } : {}
}
module "foundation" {
  source                       = "../modules/runtime-foundation"
  site                         = var.site
  platform                     = var.platform
  management_mode              = var.site == "mcdp" ? "local" : "cloud"
  approved_for_cluster_changes = var.approved_for_cluster_changes
  prepare_management_namespace = false
  create_network_policies      = false
  stage_labels                 = local.worker_labels
  depends_on                   = [kubernetes_namespace_v1.rtf]
}
resource "kubernetes_config_map_v1" "authorized_namespaces" {
  count = var.install_runtime_fabric ? 1 : 0
  metadata {
    name      = "authorized-namespaces"
    namespace = kubernetes_namespace_v1.rtf.metadata[0].name
  }
  data = { for stage, namespace in module.foundation.stage_namespaces : upper(stage) => namespace }
}
resource "kubernetes_role_binding_v1" "agent" {
  for_each = var.install_runtime_fabric ? module.foundation.stage_namespaces : {}
  metadata {
    name      = "rtf-agent"
    namespace = each.value
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "rtf:agent"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "rtf-agent"
    namespace = "rtf"
  }
}
resource "kubernetes_secret_v1" "registry" {
  count = var.install_runtime_fabric ? 1 : 0
  metadata {
    name      = "rtf-pull-secret"
    namespace = kubernetes_namespace_v1.rtf.metadata[0].name
  }
  type = "kubernetes.io/dockerconfigjson"
  data = { ".dockerconfigjson" = var.registry_config_file != null ? file(var.registry_config_file) : "" }
}
resource "helm_release" "rtf" {
  count               = var.install_runtime_fabric ? 1 : 0
  name                = "runtime-fabric"
  namespace           = kubernetes_namespace_v1.rtf.metadata[0].name
  repository          = var.chart_archive == null ? var.chart_repository : null
  repository_username = var.chart_archive == null ? var.repository_username : null
  repository_password = var.chart_archive == null ? var.repository_password : null
  chart               = var.chart_archive != null ? var.chart_archive : "rtf-agent"
  version             = var.chart_version
  values = [
    var.values_file != null ? sensitive(file(var.values_file)) : "",
    yamlencode({ global = { authorizedNamespaces = true, image = { pullSecretName = "rtf-pull-secret" } } })
  ]
  wait       = true
  timeout    = 1200
  depends_on = [kubernetes_config_map_v1.authorized_namespaces, kubernetes_role_binding_v1.agent, kubernetes_secret_v1.registry]
  lifecycle { prevent_destroy = true }
}
output "stage_namespaces" { value = module.foundation.stage_namespaces }
output "rtf_namespace" { value = kubernetes_namespace_v1.rtf.metadata[0].name }
output "rtf_install_enabled" { value = var.install_runtime_fabric }
