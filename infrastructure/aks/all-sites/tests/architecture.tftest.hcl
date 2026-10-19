mock_provider "kubernetes" {
  alias = "azure"
  mock_data "kubernetes_namespace_v1" {
    defaults = { metadata = { uid = "azure-cluster" } }
  }
}
mock_provider "kubernetes" {
  alias = "zrh"
  mock_data "kubernetes_namespace_v1" {
    defaults = { metadata = { uid = "zrh-cluster" } }
  }
}
mock_provider "kubernetes" {
  alias = "mcdp"
  mock_data "kubernetes_namespace_v1" {
    defaults = { metadata = { uid = "mcdp-cluster" } }
  }
}
variables {
  approved_for_cluster_changes = true
  connected_lab_mode           = true
  sites = {
    azure = { kubeconfig_path = "mock-azure", kube_context = "mock-azure", platform = "aks" }
    zrh   = { kubeconfig_path = "mock-zrh", kube_context = "mock-zrh", platform = "openshift" }
    mcdp  = { kubeconfig_path = "mock-mcdp", kube_context = "mock-mcdp", platform = "openshift" }
  }
}
run "three_infrastructures_nine_stages" {
  command = plan
  assert {
    condition     = length(flatten([for site in values(output.stage_namespaces) : values(site)])) == 9
    error_message = "Expected three stages on each of three sites."
  }
  assert {
    condition     = output.management_namespaces.mcdp == "fzag-mcdp-management" && output.management_namespaces.azure == null && output.management_namespaces.zrh == null
    error_message = "Only MCDP should reserve an independent management namespace."
  }
  assert {
    condition     = output.dns_profiles.azure.namespace == "kube-system" && output.dns_profiles.zrh.namespace == "openshift-dns" && output.dns_profiles.mcdp.ports == toset([5353])
    error_message = "AKS and OpenShift DNS must use platform-specific settings."
  }
}
run "same_cluster_cannot_impersonate_three_sites" {
  command = plan
  override_data {
    target = data.kubernetes_namespace_v1.zrh_identity
    values = { metadata = { uid = "azure-cluster" } }
  }
  expect_failures = [terraform_data.cluster_boundary]
}
