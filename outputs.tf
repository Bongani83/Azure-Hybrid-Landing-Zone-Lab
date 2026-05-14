output "resource_group_name" {
  value = azurerm_resource_group.hybrid_lz.name
}

output "hub_vnet_name" {
  value = azurerm_virtual_network.hub.name
}

output "spoke_vnet_name" {
  value = azurerm_virtual_network.spoke.name
}

output "onprem_sim_vnet_name" {
  value = azurerm_virtual_network.onprem.name
}

output "spoke_app_subnet_id" {
  value = azurerm_subnet.spoke_app.id
}

output "onprem_subnet_id" {
  value = azurerm_subnet.onprem.id
}
