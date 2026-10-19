terraform {
  required_version = ">= 1.7.0, < 2.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 3.3.0"
    }
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
  validation {
    condition     = contains(["aks", "openshift", "kubernetes"], var.platform)
    error_message = "Select aks, openshift or kubernetes."
  }
}
variable "management_mode" {
  type = string
  validation {
    condition     = contains(["cloud", "local"], var.management_mode)
    error_message = "Select cloud or local management."
  }
}
variable "approved_for_cluster_changes" {
  type    = bool
  default = false
}
variable "distinct_target_clusters" {
  type    = bool
  default = true
}
variable "dns_override" {
  description = "Override defaults after checking actual DNS namespace, pod labels and target ports."
  type        = object({ namespace = string, pod_labels = map(string), ports = set(number) })
  default     = null
}
locals {
  stages = toset(["dev", "int", "prod"])
  dns_defaults = var.platform == "openshift" ? {
    namespace  = "openshift-dns"
    pod_labels = { "dns.operator.openshift.io/daemonset-dns" = "default" }
    ports      = toset([5353])
    } : {
    namespace  = "kube-system"
    pod_labels = { "k8s-app" = "kube-dns" }
    ports      = toset([53])
  }
  dns = var.dns_override == null ? local.dns_defaults : var.dns_override
}
resource "kubernetes_namespace_v1" "stage" {
  for_each = local.stages
  metadata {
    name = "fzag-${var.site}-${each.key}"
    labels = {
      "app.kubernetes.io/part-of" = "fzag-runtime"
      "fzag.ch/site"              = var.site
      "fzag.ch/stage"             = each.key
    }
  }
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.approved_for_cluster_changes && var.distinct_target_clusters
      error_message = "Approval and separate target cluster identities are required."
    }
    precondition {
      condition     = var.site != "mcdp" || var.management_mode == "local"
      error_message = "MCDP must not use cloud management."
    }
  }
}
resource "kubernetes_namespace_v1" "management" {
  count = var.management_mode == "local" ? 1 : 0
  metadata {
    name = "fzag-${var.site}-management"
    labels = {
      "app.kubernetes.io/part-of" = "fzag-runtime"
      "fzag.ch/site"              = var.site
      "fzag.ch/role"              = "future-local-management"
    }
  }
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.approved_for_cluster_changes && var.distinct_target_clusters
      error_message = "Approval and separate target cluster identities are required."
    }
  }
}
locals {
  namespace_names = merge(
    { for stage, ns in kubernetes_namespace_v1.stage : stage => ns.metadata[0].name },
    var.management_mode == "local" ? { management = kubernetes_namespace_v1.management[0].metadata[0].name } : {}
  )
}
resource "kubernetes_network_policy_v1" "boundary" {
  for_each = local.namespace_names
  metadata {
    name      = "stage-boundary"
    namespace = each.value
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
    ingress {
      from {
        pod_selector {}
      }
    }
    egress {
      to {
        pod_selector {}
      }
    }
    egress {
      to {
        namespace_selector {
          match_labels = { "kubernetes.io/metadata.name" = local.dns.namespace }
        }
        pod_selector { match_labels = local.dns.pod_labels }
      }
      dynamic "ports" {
        for_each = setproduct(local.dns.ports, toset(["TCP", "UDP"]))
        content {
          port     = tostring(ports.value[0])
          protocol = ports.value[1]
        }
      }
    }
  }
}
output "stage_namespaces" {
  value = { for stage, ns in kubernetes_namespace_v1.stage : stage => ns.metadata[0].name }
}
output "management_namespace" {
  value = var.management_mode == "local" ? kubernetes_namespace_v1.management[0].metadata[0].name : null
}
output "dns_profile" { value = local.dns }
