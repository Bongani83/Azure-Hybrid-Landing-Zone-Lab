terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------

resource "azurerm_resource_group" "hybrid_lz" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# ------------------------------------------------------------
# Network Security Groups
# ------------------------------------------------------------

resource "azurerm_network_security_group" "hub_mgmt" {
  name                = "nsg-hybrid-hub-mgmt"
  location            = azurerm_resource_group.hybrid_lz.location
  resource_group_name = azurerm_resource_group.hybrid_lz.name

  tags = var.tags
}

resource "azurerm_network_security_group" "spoke_app" {
  name                = "nsg-hybrid-spoke-app"
  location            = azurerm_resource_group.hybrid_lz.location
  resource_group_name = azurerm_resource_group.hybrid_lz.name

  security_rule {
    name                       = "Allow-Hub-Admin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["3389", "22"]
    source_address_prefix      = "10.20.0.0/16"
    destination_address_prefix = "*"
    description                = "Allow RDP/SSH from Hub network only"
  }

  security_rule {
    name                       = "Allow-OnPrem-To-Spoke-Admin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["3389", "22"]
    source_address_prefix      = "192.168.50.0/24"
    destination_address_prefix = "*"
    description                = "Allow RDP/SSH from simulated on-prem network"
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "onprem_sim" {
  name                = "nsg-onprem-sim"
  location            = azurerm_resource_group.hybrid_lz.location
  resource_group_name = azurerm_resource_group.hybrid_lz.name

  security_rule {
    name                       = "Allow-OnPrem-To-Spoke"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["3389", "22"]
    source_address_prefix      = "*"
    destination_address_prefix = "10.21.0.0/16"
    description                = "Allow simulated on-prem traffic to spoke admin ports"
  }

  tags = var.tags
}

# ------------------------------------------------------------
# Virtual Networks
# ------------------------------------------------------------

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hybrid-hub"
  location            = azurerm_resource_group.hybrid_lz.location
  resource_group_name = azurerm_resource_group.hybrid_lz.name
  address_space       = ["10.20.0.0/16"]

  tags = var.tags
}

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-hybrid-spoke-app"
  location            = azurerm_resource_group.hybrid_lz.location
  resource_group_name = azurerm_resource_group.hybrid_lz.name
  address_space       = ["10.21.0.0/16"]

  tags = var.tags
}

resource "azurerm_virtual_network" "onprem" {
  name                = "vnet-onprem-sim"
  location            = azurerm_resource_group.hybrid_lz.location
  resource_group_name = azurerm_resource_group.hybrid_lz.name
  address_space       = ["192.168.50.0/24"]

  tags = var.tags
}

# ------------------------------------------------------------
# Hub Subnets
# ------------------------------------------------------------

resource "azurerm_subnet" "hub_default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.hybrid_lz.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.20.0.0/24"]
}

resource "azurerm_subnet" "hub_shared_services" {
  name                 = "snet-shared-services"
  resource_group_name  = azurerm_resource_group.hybrid_lz.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_subnet" "hub_management" {
  name                 = "snet-management"
  resource_group_name  = azurerm_resource_group.hybrid_lz.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.20.2.0/24"]
}

resource "azurerm_subnet" "hub_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hybrid_lz.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.20.254.0/26"]
}

resource "azurerm_subnet" "hub_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hybrid_lz.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.20.255.0/27"]
}

resource "azurerm_subnet_network_security_group_association" "hub_management" {
  subnet_id                 = azurerm_subnet.hub_management.id
  network_security_group_id = azurerm_network_security_group.hub_mgmt.id
}

# ------------------------------------------------------------
# Spoke Subnets
# ------------------------------------------------------------

resource "azurerm_subnet" "spoke_default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.hybrid_lz.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.21.0.0/24"]
}

resource "azurerm_subnet" "spoke_app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.hybrid_lz.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.21.1.0/24"]
}

resource "azurerm_subnet" "spoke_test" {
  name                 = "snet-test"
  resource_group_name  = azurerm_resource_group.hybrid_lz.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.21.2.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "spoke_app" {
  subnet_id                 = azurerm_subnet.spoke_app.id
  network_security_group_id = azurerm_network_security_group.spoke_app.id
}

# ------------------------------------------------------------
# Simulated On-Prem Subnet
# ------------------------------------------------------------

resource "azurerm_subnet" "onprem" {
  name                 = "snet-onprem"
  resource_group_name  = azurerm_resource_group.hybrid_lz.name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = ["192.168.50.0/26"]
}

resource "azurerm_subnet_network_security_group_association" "onprem" {
  subnet_id                 = azurerm_subnet.onprem.id
  network_security_group_id = azurerm_network_security_group.onprem_sim.id
}

# ------------------------------------------------------------
# VNet Peerings
# Note: Azure VNet peering is not transitive, so direct onprem-to-spoke
# peering is included for this cost-conscious lab simulation.
# ------------------------------------------------------------

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = azurerm_resource_group.hybrid_lz.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.hybrid_lz.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "onprem_to_hub" {
  name                      = "onprem-to-hub"
  resource_group_name       = azurerm_resource_group.hybrid_lz.name
  virtual_network_name      = azurerm_virtual_network.onprem.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub_to_onprem" {
  name                      = "hub-to-onprem"
  resource_group_name       = azurerm_resource_group.hybrid_lz.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.onprem.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "onprem_to_spoke" {
  name                      = "onprem-to-spoke"
  resource_group_name       = azurerm_resource_group.hybrid_lz.name
  virtual_network_name      = azurerm_virtual_network.onprem.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_to_onprem" {
  name                      = "spoke-to-onprem"
  resource_group_name       = azurerm_resource_group.hybrid_lz.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.onprem.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
