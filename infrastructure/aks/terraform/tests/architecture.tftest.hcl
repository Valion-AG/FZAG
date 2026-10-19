# Provider mocks only: no Azure authentication, calls or resources.
mock_provider "azapi" {}
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "11111111-1111-1111-1111-111111111111"
    }
  }
}
variables {
  admin_object_id    = "22222222-2222-2222-2222-222222222222"
  kubernetes_version = "1.36.4"
}
run "unapproved_creation_is_blocked" {
  command         = plan
  expect_failures = [azapi_resource.demo]
}
run "azure_runtime_matches_diagram" {
  command = plan
  variables {
    approved_for_billable_creation = true
  }
  assert {
    condition     = azapi_resource.demo.location == "switzerlandnorth" && endswith(azapi_resource.demo.parent_id, "/resourceGroups/flughafen-zürich-poc")
    error_message = "Runtime must use Switzerland North and the exact existing RG."
  }
  assert {
    condition     = azapi_resource.demo.body.properties.agentPoolProfiles[0].count == 2 && azapi_resource.demo.body.sku.tier == "Free"
    error_message = "Unexpected node count or paid AKS management tier."
  }
  assert {
    condition     = azapi_resource.demo.body.properties.disableLocalAccounts && azapi_resource.demo.body.properties.aadProfile.enableAzureRBAC
    error_message = "Expected Entra RBAC and disabled local accounts."
  }
  assert {
    condition     = azapi_resource.demo.body.properties.networkProfile.networkDataplane == "cilium"
    error_message = "Namespace network policies require an enforcing network engine."
  }
}
