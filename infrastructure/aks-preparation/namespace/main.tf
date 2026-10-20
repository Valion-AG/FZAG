terraform {
  backend "local" {}
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "= 3.3.0" }
  }
}
variable "kubeconfig_path" { type = string }
variable "kube_context" {
  type = string
  validation {
    condition = length(trimspace(var.kube_context)) > 0
    error_message = "Specify the exact approved target context."
  }
}
provider "kubernetes" {
  config_path = var.kubeconfig_path
  config_context = var.kube_context
}
resource "kubernetes_namespace_v1" "mulesoft" {
  metadata {
    name = "mulesoft"
    labels = {
      "app.kubernetes.io/part-of" = "fzag-interop"
      purpose = "mulesoft-preparation"
    }
  }
  lifecycle { prevent_destroy = true }
}
output "namespace" { value = kubernetes_namespace_v1.mulesoft.metadata[0].name }
