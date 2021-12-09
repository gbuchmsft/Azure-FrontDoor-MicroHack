#######################################################################
## Create Bastion network
#######################################################################

resource "azurerm_virtual_network" "bastion-vnet" {
  name                = "bastion-vnet"
  location            = var.location-bastion-network
  resource_group_name = azurerm_resource_group.frontdoor.name
  address_space       = ["10.100.50.0/23"]

  tags = var.resource_tags
}

resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.frontdoor.name
  virtual_network_name = azurerm_virtual_network.bastion-vnet.name
  address_prefixes       = ["10.100.50.224/27"]

}

#######################################################################
## Create peering between bastion-network and WEU
#######################################################################

module "peering1" {
#  depends_on           = [azurerm_virtual_network_gateway.vgw]
  source               = "aztfm/virtual-network-peering/azurerm"
  version              = ">=1.0.0"
  resource_group_name  = azurerm_resource_group.frontdoor.name
  virtual_network_name = azurerm_virtual_network.bastion-vnet.name
  peerings = [
    {
      name                      = azurerm_virtual_network.client-westeurope-vnet.name
      remote_virtual_network_id = azurerm_virtual_network.client-westeurope-vnet.id
#      allow_gateway_transit     = true
    },
    {
      name                      = azurerm_virtual_network.client-uscentral-vnet.name
      remote_virtual_network_id = azurerm_virtual_network.client-uscentral-vnet.id
#      allow_gateway_transit     = true
    },
    {
      name                      = azurerm_virtual_network.client-southeastasia-vnet.name
      remote_virtual_network_id = azurerm_virtual_network.client-southeastasia-vnet.id
#      allow_gateway_transit     = true
    }
  ]
}

module "peering2" {
  source               = "aztfm/virtual-network-peering/azurerm"
  version              = ">=1.0.0"
  resource_group_name  = azurerm_resource_group.client-westeurope.name
  virtual_network_name = azurerm_virtual_network.client-westeurope-vnet.name
  peerings = [
    {
      name                      = module.peering1.peerings[azurerm_virtual_network.client-westeurope-vnet.name].virtual_network_name
      remote_virtual_network_id = azurerm_virtual_network.bastion-vnet.id
#      use_remote_gateways       = true
    }    
  ]
}

module "peering3" {
   source               = "aztfm/virtual-network-peering/azurerm"
   version              = ">=1.0.0"
   resource_group_name  = azurerm_resource_group.client-uscentral.name
   virtual_network_name = azurerm_virtual_network.client-uscentral-vnet.name
   peerings = [
     {
       name                      = module.peering1.peerings[azurerm_virtual_network.client-uscentral-vnet.name].virtual_network_name
       remote_virtual_network_id = azurerm_virtual_network.bastion-vnet.id
 #      use_remote_gateways       = true
     }
   ]
 }

 module "peering4" {
   source               = "aztfm/virtual-network-peering/azurerm"
   version              = ">=1.0.0"
   resource_group_name  = azurerm_resource_group.client-southeastasia.name
   virtual_network_name = azurerm_virtual_network.client-southeastasia-vnet.name
   peerings = [
     {
       name                      = module.peering1.peerings[azurerm_virtual_network.client-southeastasia-vnet.name].virtual_network_name
       remote_virtual_network_id = azurerm_virtual_network.bastion-vnet.id
 #      use_remote_gateways       = true
     }
   ]
 }

#######################################################################
## Create peering between bastion-network and USC
#######################################################################

## module "peering1" {
## #  depends_on           = [azurerm_virtual_network_gateway.vgw]
##   source               = "aztfm/virtual-network-peering/azurerm"
##   version              = ">=1.0.0"
##   resource_group_name  = azurerm_resource_group.frontdoor.name
##   virtual_network_name = azurerm_virtual_network.bastion-vnet.name
##   peerings = [
##     {
##       name                      = azurerm_virtual_network.client-uscentral-vnet.name
##       remote_virtual_network_id = azurerm_virtual_network.client-uscentral-vnet.id
## #      allow_gateway_transit     = true
##     }
##   ]
## }
## 
## module "peering2" {
##   source               = "aztfm/virtual-network-peering/azurerm"
##   version              = ">=1.0.0"
##   resource_group_name  = azurerm_resource_group.client-uscentral.name
##   virtual_network_name = azurerm_virtual_network.client-uscentral-vnet.name
##   peerings = [
##     {
##       name                      = module.peering1.peerings[azurerm_virtual_network.client-uscentral-vnet.name].virtual_network_name
##       remote_virtual_network_id = azurerm_virtual_network.bastion-vnet.id
## #      use_remote_gateways       = true
##     },
##     {
##       name                      = module.peering1.peerings[azurerm_virtual_network.client-westeurope-vnet.name].virtual_network_name
##       remote_virtual_network_id = azurerm_virtual_network.bastion-vnet.id
## #      use_remote_gateways       = true
##     }
##   ]
## }

#######################################################################
## Create peering between bastion-network and SEA
#######################################################################

#######################################################################
## Create Bastion
#######################################################################
resource "azurerm_public_ip" "bastion-hub-1-pubip" {
  name                = "bastion-hub-1-pubip"
  location            = var.location-bastion-network
  resource_group_name = azurerm_resource_group.frontdoor.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-hub-1" {
  name                = "bastion-hub-1"
  location            = var.location-bastion-network
  resource_group_name = azurerm_resource_group.frontdoor.name

  ip_configuration {
    name                 = "bastion-hub-1-configuration"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-hub-1-pubip.id
  }
}