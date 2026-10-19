terraform {
  required_version = ">= 1.7.0, < 2.0.0"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "= 3.3.0" }
  }
}
variable "sites" {
  description = "Three authorized existing clusters. Paths and contexts must refer to the intended infrastructure."
  type = map(object({
    kubeconfig_path = string
    kube_context    = string
    platform        = string
    dns_override    = optional(object({ namespace = string, pod_labels = map(string), ports = set(number) }), null)
  }))
  validation {
    condition     = toset(keys(var.sites)) == toset(["azure", "zrh", "mcdp"])
    error_message = "Supply exactly azure, zrh and mcdp cluster configurations."
  }
  validation {
    condition     = alltrue([for site in values(var.sites) : length(trimspace(site.kube_context)) > 0 && contains(["aks", "openshift", "kubernetes"], site.platform)])
    error_message = "Each site needs an explicit context and supported platform profile."
  }
}
variable "approved_for_cluster_changes" {
  type    = bool
  default = false
}
provider "kubernetes" {
  alias          = "azure"
  config_path    = pathexpand(var.sites["azure"].kubeconfig_path)
  config_context = var.sites["azure"].kube_context
}
data "kubernetes_namespace_v1" "azure_identity" {
  provider = kubernetes.azure
  metadata { name = "kube-system" }
}
module "azure" {
  source                       = "../modules/runtime-foundation"
  providers                    = { kubernetes = kubernetes.azure }
  site                         = "azure"
  platform                     = var.sites["azure"].platform
  management_mode              = "cloud"
  dns_override                 = var.sites["azure"].dns_override
  approved_for_cluster_changes = var.approved_for_cluster_changes && var.connected_lab_mode
  depends_on                   = [terraform_data.cluster_boundary]
}
provider "kubernetes" {
  alias          = "zrh"
  config_path    = pathexpand(var.sites["zrh"].kubeconfig_path)
  config_context = var.sites["zrh"].kube_context
}
data "kubernetes_namespace_v1" "zrh_identity" {
  provider = kubernetes.zrh
  metadata { name = "kube-system" }
}
module "zrh" {
  source                       = "../modules/runtime-foundation"
  providers                    = { kubernetes = kubernetes.zrh }
  site                         = "zrh"
  platform                     = var.sites["zrh"].platform
  management_mode              = "cloud"
  dns_override                 = var.sites["zrh"].dns_override
  approved_for_cluster_changes = var.approved_for_cluster_changes && var.connected_lab_mode
  depends_on                   = [terraform_data.cluster_boundary]
}
provider "kubernetes" {
  alias          = "mcdp"
  config_path    = pathexpand(var.sites["mcdp"].kubeconfig_path)
  config_context = var.sites["mcdp"].kube_context
}
data "kubernetes_namespace_v1" "mcdp_identity" {
  provider = kubernetes.mcdp
  metadata { name = "kube-system" }
}
module "mcdp" {
  source                       = "../modules/runtime-foundation"
  providers                    = { kubernetes = kubernetes.mcdp }
  site                         = "mcdp"
  platform                     = var.sites["mcdp"].platform
  management_mode              = "local"
  dns_override                 = var.sites["mcdp"].dns_override
  approved_for_cluster_changes = var.approved_for_cluster_changes && var.connected_lab_mode
  depends_on                   = [terraform_data.cluster_boundary]
}
locals {
  cluster_uids             = [data.kubernetes_namespace_v1.azure_identity.metadata[0].uid, data.kubernetes_namespace_v1.zrh_identity.metadata[0].uid, data.kubernetes_namespace_v1.mcdp_identity.metadata[0].uid]
  distinct_target_clusters = length(distinct(local.cluster_uids)) == 3
}
output "stage_namespaces" {
  value = { azure = module.azure.stage_namespaces, zrh = module.zrh.stage_namespaces, mcdp = module.mcdp.stage_namespaces }
}
output "management_namespaces" {
  value = { azure = module.azure.management_namespace, zrh = module.zrh.management_namespace, mcdp = module.mcdp.management_namespace }
}
variable "connected_lab_mode" {
  description = "All-sites root is for a connected lab only. True MCDP airgap uses single-site execution inside MCDP."
  type        = bool
  default     = false
}
output "dns_profiles" {
  value = { azure = module.azure.dns_profile, zrh = module.zrh.dns_profile, mcdp = module.mcdp.dns_profile }
}
resource "terraform_data" "cluster_boundary" {
  input = local.cluster_uids
  lifecycle {
    precondition {
      condition     = local.distinct_target_clusters
      error_message = "Azure, ZRH and MCDP must be three distinct clusters."
    }
  }
}
