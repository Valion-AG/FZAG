mock_provider "kubernetes" {}
mock_provider "helm" {}
variables {
  site                         = "azure"
  kubeconfig_path              = "mock"
  kube_context                 = "mock-cluster"
  approved_for_cluster_changes = true
}
run "foundation_installs_argocd_not_vendor_release" {
  command = plan
  assert {
    condition     = helm_release.argocd.chart == "argo-cd" && !output.runtime_fabric_requested
    error_message = "Default bootstrap must install Argo CD without requesting RTF."
  }
  assert {
    condition     = length(kubernetes_secret_v1.inputs.data) == 0 && length(kubernetes_secret_v1.inputs.binary_data) == 0
    error_message = "Foundation-only bootstrap must not carry vendor credentials or chart."
  }
}
run "explicit_cluster_approval_required" {
  command = plan
  variables { approved_for_cluster_changes = false }
  expect_failures = [kubernetes_namespace_v1.argocd]
}
run "vendor_install_blocked_without_inputs" {
  command = plan
  variables { install_rtf = true }
  expect_failures = [kubernetes_namespace_v1.argocd]
}
run "private_vendor_inputs_are_mounted_not_installed_by_terraform" {
  command = plan
  variables {
    install_rtf              = true
    vendor_support_confirmed = true
    private_inputs_directory = "tests/fixtures"
  }
  assert {
    condition     = output.runtime_fabric_requested && length(kubernetes_secret_v1.inputs.binary_data) == 1 && helm_release.application.name == "fzag-runtime-bootstrap"
    error_message = "RTF must use mounted vendor inputs and the Argo Application, not a Terraform RTF release."
  }
}
run "mcdp_needs_explicit_offline_confirmation" {
  command = plan
  variables {
    site                     = "mcdp"
    install_rtf              = true
    vendor_support_confirmed = true
    private_inputs_directory = "tests/fixtures"
  }
  expect_failures = [kubernetes_namespace_v1.argocd]
}
