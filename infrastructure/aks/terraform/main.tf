terraform {
  required_version = ">= 1.5.7, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.59.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "= 2.13.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}
provider "azapi" {
  subscription_id = var.subscription_id
}
variable "subscription_id" {
  type    = string
  default = "6f5e5d9c-cd3f-4dec-8ade-410c01c8195f"
}
variable "admin_object_id" {
  description = "Entra object ID of the authorized demo administrator."
  type        = string
}
variable "admin_cidrs" {
  type    = set(string)
  default = ["46.14.148.34/32"]
  validation {
    condition     = length(var.admin_cidrs) > 0 && !contains(var.admin_cidrs, "0.0.0.0/0")
    error_message = "Specify restricted administration source CIDRs."
  }
}
variable "kubernetes_version" {
  description = "Select an exact currently offered patch after controller compatibility review."
  type        = string
}
variable "approved_for_billable_creation" {
  type        = bool
  default     = false
  description = "Keep false until user approves incremental costs and preflight passes."
}
data "azurerm_client_config" "current" {}
# AzureRM 4.59 rejects the umlaut in the existing RG name during validation.
# AzAPI addresses the existing RG by its exact ARM ID; it does not rename it.
resource "azapi_resource" "demo" {
  type      = "Microsoft.ContainerService/managedClusters@2025-04-01"
  name      = "aks-fzag-gitops"
  location  = "switzerlandnorth"
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/flughafen-zürich-poc"
  identity {
    type = "SystemAssigned"
  }
  body = {
    sku = { name = "Base", tier = "Free" }
    properties = {
      dnsPrefix            = "fzag-gitops"
      kubernetesVersion    = var.kubernetes_version
      nodeResourceGroup    = "rg-fzag-aks-gitops-nodes"
      enableRBAC           = true
      disableLocalAccounts = true
      aadProfile = {
        managed         = true
        enableAzureRBAC = true
        tenantID        = data.azurerm_client_config.current.tenant_id
      }
      apiServerAccessProfile = { authorizedIPRanges = var.admin_cidrs }
      agentPoolProfiles = [{
        name            = "system"
        count           = 2
        vmSize          = "Standard_F4s_v2"
        osDiskSizeGB    = 64
        osDiskType      = "Managed"
        osType          = "Linux"
        type            = "VirtualMachineScaleSets"
        mode            = "System"
        maxPods         = 30
        upgradeSettings = { maxSurge = "1" }
      }]
      networkProfile = {
        networkPlugin       = "azure"
        networkPluginMode   = "overlay"
        podCidr             = "10.244.0.0/16"
        serviceCidr         = "10.240.0.0/16"
        dnsServiceIP        = "10.240.0.10"
        loadBalancerSku     = "standard"
        outboundType        = "loadBalancer"
        loadBalancerProfile = { managedOutboundIPs = { count = 1 } }
      }
    }
  }
  tags = { purpose = "fzag-gitops-poc", managedBy = "Terraform" }
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.approved_for_billable_creation
      error_message = "Obtain explicit spending approval and pass quota/provider/version checks before deployment."
    }
  }
}
resource "azurerm_role_assignment" "admin" {
  scope                = azapi_resource.demo.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.admin_object_id
}
output "cluster_name" {
  value = azapi_resource.demo.name
}
output "resource_group_name" {
  value = "flughafen-zürich-poc"
}
