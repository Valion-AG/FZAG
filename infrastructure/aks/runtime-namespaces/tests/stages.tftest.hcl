mock_provider "kubernetes" {}
variables {
  kubeconfig_path              = "test-only-kubeconfig"
  kube_context                 = "mock-cluster"
  approved_for_cluster_changes = true
}
run "azure_has_three_stages" {
  command = plan
  assert {
    condition     = toset(values(output.stage_namespaces)) == toset(["fzag-azure-dev", "fzag-azure-int", "fzag-azure-prod"])
    error_message = "Azure must have exactly DEV, INT and PROD stage namespaces."
  }
}
run "mcdp_has_separate_names" {
  command = plan
  variables {
    site = "mcdp"
  }
  assert {
    condition     = toset(values(output.stage_namespaces)) == toset(["fzag-mcdp-dev", "fzag-mcdp-int", "fzag-mcdp-prod"])
    error_message = "MCDP namespaces must use their own site prefix."
  }
}
run "zrh_has_separate_names" {
  command = plan
  variables {
    site = "zrh"
  }
  assert {
    condition     = toset(values(output.stage_namespaces)) == toset(["fzag-zrh-dev", "fzag-zrh-int", "fzag-zrh-prod"])
    error_message = "ZRH namespaces must use their own site prefix."
  }
}
