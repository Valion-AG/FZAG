terraform {
  required_version = ">= 1.7.0, < 2.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 3.3.0"
    }
  }
}

variable "kubeconfig_path" {
  description = "Explicit authorized kubeconfig. Never commit the file."
  type        = string
}
variable "kube_context" {
  description = "Explicit intended cluster context; avoids using whichever context is current."
  type        = string
  validation {
    condition     = length(trimspace(var.kube_context)) > 0
    error_message = "An explicit target context is required."
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
variable "approved_for_cluster_changes" {
  type    = bool
  default = false
}

provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig_path)
  config_context = var.kube_context
}

locals {
  stages = toset(["dev", "int", "prod"])
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
      condition     = var.approved_for_cluster_changes
      error_message = "Review the exact target cluster and obtain approval before creating stage namespaces."
    }
  }
}

# Initial empty runtime namespaces: permit within-stage traffic and cluster DNS.
# Gateway ingress, control-plane egress and backend access must be added when
# their actual ports/destinations are known. This is not a full air-gap boundary.
resource "kubernetes_network_policy_v1" "stage_boundary" {
  for_each = local.stages
  metadata {
    name      = "stage-boundary"
    namespace = kubernetes_namespace_v1.stage[each.key].metadata[0].name
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
          match_labels = { "kubernetes.io/metadata.name" = "kube-system" }
        }
        pod_selector {
          match_labels = { "k8s-app" = "kube-dns" }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

output "stage_namespaces" {
  value = { for stage, ns in kubernetes_namespace_v1.stage : stage => ns.metadata[0].name }
}
