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
variable "cluster_name" {
  type    = string
  default = "aks-fzag-runtime"
}
variable "resource_group_name" {
  type    = string
  default = "flughafen-zürich-poc"
}
variable "node_resource_group_name" {
  type    = string
  default = "rg-fzag-runtime-nodes"
}
variable "node_count" {
  type    = number
  default = 2
  validation {
    condition     = var.node_count >= 2 && floor(var.node_count) == var.node_count
    error_message = "RTF template requires at least two nodes."
  }
}
variable "node_vm_size" {
  type    = string
  default = "Standard_D4as_v5"
  validation {
    condition     = contains(["Standard_D4as_v5", "Standard_D8as_v5", "Standard_D16as_v5"], var.node_vm_size)
    error_message = "Use a reviewed x86-64 Dasv5 size with at least 16 GiB RAM; the old 8 GiB F4s v2 candidate is unsuitable. Review regional availability separately."
  }
}
variable "node_os_disk_size_gb" {
  type    = number
  default = 512
  validation {
    condition     = var.node_os_disk_size_gb >= 512 && floor(var.node_os_disk_size_gb) == var.node_os_disk_size_gb
    error_message = "Use at least 512 GiB provisioned OS disk here to leave headroom above the 250 GiB available-space requirement. Verify actual free space later."
  }
}
variable "rtf_platform_review_confirmed" {
  type        = bool
  default     = false
  description = "Confirm vendor/chart/Kubernetes compatibility, regional SKU availability, capacity, quota and cost review before provisioning."
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
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Replace the template placeholder with an exact supported Kubernetes patch."
  }
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
  name      = var.cluster_name
  location  = "switzerlandnorth"
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  identity {
    type = "SystemAssigned"
  }
  body = {
    sku = { name = "Base", tier = "Free" }
    properties = {
      dnsPrefix            = var.cluster_name
      kubernetesVersion    = var.kubernetes_version
      nodeResourceGroup    = var.node_resource_group_name
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
        count           = var.node_count
        vmSize          = var.node_vm_size
        osDiskSizeGB    = var.node_os_disk_size_gb
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
        networkDataplane    = "cilium"
        podCidr             = "10.244.0.0/16"
        serviceCidr         = "10.240.0.0/16"
        dnsServiceIP        = "10.240.0.10"
        loadBalancerSku     = "standard"
        outboundType        = "loadBalancer"
        loadBalancerProfile = { managedOutboundIPs = { count = 1 } }
      }
    }
  }
  tags = { purpose = "fzag-runtime-poc", managedBy = "Terraform" }
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.approved_for_billable_creation
      error_message = "Obtain explicit spending approval and pass quota/provider/version checks before deployment."
    }
    precondition {
      condition     = var.rtf_platform_review_confirmed
      error_message = "Template only: confirm exact RTF/platform support and refresh sizing, regional availability, quota and costs before provisioning."
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
  value = var.resource_group_name
}
