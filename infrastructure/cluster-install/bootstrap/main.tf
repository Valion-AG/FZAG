terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  backend "local" {}
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "= 3.3.0" }
    helm       = { source = "hashicorp/helm", version = "= 3.3.0" }
  }
}
variable "kubeconfig_path" { type = string }
variable "kube_context" {
  type = string
  validation {
    condition     = length(trimspace(var.kube_context)) > 0
    error_message = "Specify the exact target context; do not rely on the current context."
  }
}
variable "site" {
  type = string
  validation {
    condition     = contains(["azure", "zrh", "mcdp"], var.site)
    error_message = "Use azure, zrh or mcdp."
  }
}
variable "approved_for_cluster_changes" { default = false }
variable "install_rtf" { default = false }
variable "vendor_support_confirmed" { default = false }
variable "mcdp_offline_support_confirmed" { default = false }
variable "repository_url" { default = "https://github.com/Valion-AG/FZAG.git" }
variable "repository_revision" { default = "main" }
variable "repository_path" { default = "infrastructure/cluster-install" }
variable "argocd_chart_repository" { default = "https://argoproj.github.io/argo-helm" }
variable "argocd_chart_version" { default = "10.10.5" }
variable "argocd_image_repository" { default = "quay.io/argoproj/argocd" }
variable "argocd_image_tag" { default = "v3.5.5" }
variable "argocd_extra_values_file" {
  type    = string
  default = null
}
variable "private_inputs_directory" {
  description = "Private directory: vendor-values.yaml, registry.json, rtf-agent.tgz. Optional git-username/git-password files for private Git."
  type        = string
  default     = null
}
variable "git_credentials_available" { default = false }

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
locals {
  private_dir      = var.private_inputs_directory == null ? "" : pathexpand(var.private_inputs_directory)
  rtf_inputs_exist = alltrue([for name in ["vendor-values.yaml", "registry.json", "rtf-agent.tgz"] : fileexists("${local.private_dir}/${name}")])
  plugin_config = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ConfigManagementPlugin"
    metadata   = { name = "fzag-rtf" }
    spec = {
      version          = "v1"
      generate         = { command = ["bash", "/opt/fzag/render.sh"] }
      preserveFileMode = false
      provideGitCreds  = false
    }
  }
  argo_values = {
    global         = { image = { repository = var.argocd_image_repository, tag = var.argocd_image_tag } }
    dex            = { enabled = false }
    notifications  = { enabled = false }
    applicationSet = { replicas = 0 }
    configs = {
      cm     = { "timeout.reconciliation" = "60s" }
      params = { "reposerver.parallelism.limit" = 1 }
    }
    server = { service = { type = "ClusterIP" } }
    repoServer = {
      podAnnotations = { "fzag/config-hash" = sha256(jsonencode(local.plugin_config)), "fzag/renderer-hash" = filesha256("${path.module}/../renderer/render.sh") }
      extraContainers = [{
        name            = "fzag-rtf"
        image           = "${var.argocd_image_repository}:${var.argocd_image_tag}"
        command         = ["/var/run/argocd/argocd-cmp-server"]
        env             = [{ name = "FZAG_INSTALL_RTF", value = tostring(var.install_rtf) }, { name = "FZAG_SITE", value = var.site }]
        securityContext = { runAsNonRoot = true, runAsUser = 999, allowPrivilegeEscalation = false }
        resources       = { requests = { cpu = "50m", memory = "128Mi" }, limits = { cpu = "500m", memory = "512Mi" } }
        volumeMounts = [
          { name = "var-files", mountPath = "/var/run/argocd" },
          { name = "plugins", mountPath = "/home/argocd/cmp-server/plugins" },
          { name = "fzag-plugin", mountPath = "/home/argocd/cmp-server/config/plugin.yaml", subPath = "plugin.yaml" },
          { name = "fzag-plugin", mountPath = "/opt/fzag/render.sh", subPath = "render.sh" },
          { name = "fzag-inputs", mountPath = "/var/run/fzag-inputs", readOnly = true },
          { name = "fzag-cmp-tmp", mountPath = "/tmp" }
        ]
      }]
      volumes = [
        { name = "fzag-plugin", configMap = { name = "fzag-rtf-plugin" } },
        { name = "fzag-inputs", secret = { secretName = "fzag-rtf-inputs" } },
        { name = "fzag-cmp-tmp", emptyDir = {} }
      ]
    }
  }
}
resource "kubernetes_namespace_v1" "argocd" {
  metadata { name = "argocd" }
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.approved_for_cluster_changes
      error_message = "Review the explicit target context and approve cluster bootstrap first."
    }
    precondition {
      condition     = !var.install_rtf || (var.vendor_support_confirmed && local.rtf_inputs_exist)
      error_message = "RTF needs vendor support confirmation and private vendor-values.yaml, registry.json and rtf-agent.tgz."
    }
    precondition {
      condition     = !var.install_rtf || sum([for name in ["vendor-values.yaml", "registry.json", "rtf-agent.tgz"] : try(length(filebase64("${local.private_dir}/${name}")), 0)]) < 1200000
      error_message = "Private inputs exceed this Secret-based adapter's conservative size limit; use a reviewed artifact fetch/mount adapter."
    }
    precondition {
      condition     = !var.install_rtf || var.site != "mcdp" || var.mcdp_offline_support_confirmed
      error_message = "Confirm the actual disconnected/private-control-plane installation path before enabling MCDP RTF."
    }
  }
}
resource "kubernetes_config_map_v1" "plugin" {
  metadata {
    name      = "fzag-rtf-plugin"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }
  data = {
    "plugin.yaml" = yamlencode(local.plugin_config)
    "render.sh"   = file("${path.module}/../renderer/render.sh")
  }
}
resource "kubernetes_secret_v1" "inputs" {
  metadata {
    name      = "fzag-rtf-inputs"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }
  binary_data = var.install_rtf ? {
    "rtf-agent.tgz" = filebase64("${local.private_dir}/rtf-agent.tgz")
  } : {}
  data = var.install_rtf ? {
    "vendor-values.yaml" = file("${local.private_dir}/vendor-values.yaml")
    "registry.json"      = file("${local.private_dir}/registry.json")
  } : {}
}
resource "kubernetes_secret_v1" "git" {
  count = var.git_credentials_available ? 1 : 0
  metadata {
    name      = "fzag-git-repository"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels    = { "argocd.argoproj.io/secret-type" = "repository" }
  }
  data = {
    type     = "git"
    url      = var.repository_url
    username = file("${local.private_dir}/git-username")
    password = file("${local.private_dir}/git-password")
  }
}
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = var.argocd_chart_repository
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  values     = concat([yamlencode(local.argo_values)], var.argocd_extra_values_file == null ? [] : [file(var.argocd_extra_values_file)])
  wait       = true
  timeout    = 900
  depends_on = [kubernetes_config_map_v1.plugin, kubernetes_secret_v1.inputs]
  lifecycle { prevent_destroy = true }
}
resource "helm_release" "application" {
  name      = "fzag-runtime-bootstrap"
  namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  chart     = "${path.module}/../charts/bootstrap-application"
  values = [yamlencode({
    site       = var.site
    repository = var.repository_url
    revision   = var.repository_revision
    path       = var.repository_path
  })]
  wait       = true
  timeout    = 120
  depends_on = [helm_release.argocd, kubernetes_secret_v1.git]
  lifecycle { prevent_destroy = true }
}
output "application_name" { value = "fzag-${var.site}-runtime" }
output "target_context" { value = var.kube_context }
output "runtime_fabric_requested" { value = var.install_rtf }
