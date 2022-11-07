resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.cluster_name
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name       = "default"
    node_count = "1"
    vm_size    = "standard_d2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  http_application_routing_enabled = true
}

resource "azurerm_kubernetes_cluster_node_pool" "mem" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  name                  = "mem"
  node_count            = "1"
  vm_size               = "standard_ds11_v2"
}