terraform {
  backend "local" {}
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "= 3.3.0" }
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
  description = "Legacy compatibility flag. RTF installation must be reconciled by Argo CD for UC 1B."
  type        = bool
  default     = false
  validation {
    condition     = !var.install_runtime_fabric
    error_message = "Direct Terraform/Helm RTF installation is disabled: use the Argo CD GitOps workflow required by UC 1B."
  }
}
provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig_path)
  config_context = var.kube_context
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
module "foundation" {
  source                       = "../modules/runtime-foundation"
  site                         = var.site
  platform                     = var.platform
  management_mode              = var.site == "mcdp" ? "local" : "cloud"
  approved_for_cluster_changes = var.approved_for_cluster_changes
  prepare_management_namespace = false
  create_network_policies      = false
  depends_on                   = [kubernetes_namespace_v1.rtf]
}
output "stage_namespaces" { value = module.foundation.stage_namespaces }
output "rtf_namespace" { value = kubernetes_namespace_v1.rtf.metadata[0].name }
output "rtf_install_enabled" { value = false }
