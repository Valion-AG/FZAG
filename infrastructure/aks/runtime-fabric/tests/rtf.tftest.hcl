mock_provider "kubernetes" {}
variables {
  site = "azure"
  platform = "aks"
  kubeconfig_path = "mock-only"
  kube_context = "mock-azure"
  approved_for_cluster_changes = true
}
run "legacy_namespace_preparation_only" {
  command = plan
  assert {
    condition = output.rtf_namespace == "rtf" && length(output.stage_namespaces) == 3 && !output.rtf_install_enabled
    error_message = "The legacy bootstrap root must not install Runtime Fabric."
  }
}
run "direct_install_is_rejected" {
  command = plan
  variables { install_runtime_fabric = true }
  expect_failures = [var.install_runtime_fabric]
}
run "mcdp_namespace_preparation_only" {
  command = plan
  variables {
    site = "mcdp"
    platform = "openshift"
  }
  assert {
    condition = output.stage_namespaces.dev == "fzag-mcdp-dev" && !output.rtf_install_enabled
    error_message = "MCDP preparation must not install a runtime or management plane."
  }
}
