mock_provider "kubernetes" {}
mock_provider "helm" {}
variables {
  site                         = "azure"
  platform                     = "aks"
  kubeconfig_path              = "mock-only"
  kube_context                 = "mock-azure"
  approved_for_cluster_changes = true
}
run "prepare_without_license" {
  command = plan
  assert {
    condition     = output.rtf_namespace == "rtf" && length(output.stage_namespaces) == 3
    error_message = "Preparation must create the RTF namespace and three worker namespaces."
  }
  assert {
    condition     = length(helm_release.rtf) == 0 && length(kubernetes_secret_v1.registry) == 0 && length(kubernetes_role_binding_v1.agent) == 0
    error_message = "Preparation must not install RTF or create credential/agent resources."
  }
}
run "activation_cannot_be_enabled_without_prerequisites" {
  command = plan
  variables {
    install_runtime_fabric = true
    organization_id        = "mock-org"
    environment_ids        = { dev = "mock-dev", int = "mock-int", prod = "mock-prod" }
  }
  expect_failures = [var.install_runtime_fabric]
}
run "mcdp_preparation_is_runtime_only" {
  command = plan
  variables {
    site     = "mcdp"
    platform = "openshift"
  }
  assert {
    condition     = output.stage_namespaces.dev == "fzag-mcdp-dev" && !output.rtf_install_enabled
    error_message = "MCDP preparation must stay inactive without vendor-confirmed prerequisites."
  }
}
run "authorized_workers_are_wired_before_helm" {
  command = plan
  variables {
    install_runtime_fabric     = true
    entitlements_confirmed     = true
    platform_support_confirmed = true
    network_reviewed           = true
    organization_id            = "mock-org"
    environment_ids            = { dev = "mock-dev", int = "mock-int", prod = "mock-prod" }
    chart_version              = "0.0.0"
    chart_repository           = "https://example.invalid/mock-only"
    values_file                = "tests/fixtures/mock-values.yaml"
    registry_config_file       = "tests/fixtures/mock-registry.json"
  }
  assert {
    condition     = length(helm_release.rtf) == 1 && length(kubernetes_role_binding_v1.agent) == 3 && kubernetes_config_map_v1.authorized_namespaces[0].data["DEV"] == "fzag-azure-dev"
    error_message = "RTF install must wire all three worker namespaces before Helm."
  }
}
