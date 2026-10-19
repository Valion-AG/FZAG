terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "= 3.3.0" }
  }
}
variable "kubeconfig_path" { type = string }
variable "kube_context" {
  type = string
  validation {
    condition     = length(trimspace(var.kube_context)) > 0
    error_message = "Specify the intended cluster context."
  }
}
variable "site" {
  type    = string
  default = "azure"
  validation {
    condition     = contains(["azure", "zrh", "mcdp"], var.site)
    error_message = "Select azure, zrh or mcdp."
  }
}
variable "platform" {
  type    = string
  default = "aks"
}
variable "management_mode" {
  type    = string
  default = null
  validation {
    condition     = var.site != "mcdp" || var.management_mode == null || var.management_mode == "local"
    error_message = "MCDP requires local management."
  }
}
variable "dns_override" {
  type    = object({ namespace = string, pod_labels = map(string), ports = set(number) })
  default = null
}
variable "approved_for_cluster_changes" {
  type    = bool
  default = false
}
provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig_path)
  config_context = var.kube_context
}
module "foundation" {
  source                       = "../modules/runtime-foundation"
  site                         = var.site
  platform                     = var.platform
  management_mode              = var.site == "mcdp" ? "local" : (var.management_mode == null ? "cloud" : var.management_mode)
  dns_override                 = var.dns_override
  approved_for_cluster_changes = var.approved_for_cluster_changes
}
output "stage_namespaces" { value = module.foundation.stage_namespaces }
output "management_namespace" { value = module.foundation.management_namespace }
output "dns_profile" { value = module.foundation.dns_profile }
