#######################################################################
## Get Data like public IP from location
#######################################################################
data "http" "myip-usc" {
  url = "https://api.ipify.org/"
}

#######################################################################
## Create Virtual Network - client USC
#######################################################################
resource "azurerm_virtual_network" "client-uscentral-vnet" {
  name                = "client-uscentral-vnet"
  location            = var.location-client-uscentral
  resource_group_name = azurerm_resource_group.client-uscentral.name
  address_space       = ["10.100.20.0/23"]

  tags = {
    environment = "client-uscentral"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

#######################################################################
## Create Subnets - client USC
#######################################################################
resource "azurerm_subnet" "client-uscentral-subnet-1" {
  name                 = "client-uscentral-subnet-1"
  resource_group_name  = azurerm_resource_group.client-uscentral.name
  virtual_network_name = azurerm_virtual_network.client-uscentral-vnet.name
  address_prefixes       = ["10.100.20.0/25"]
}
resource "azurerm_subnet" "client-uscentral-subnet-2" {
  name                 = "client-uscentral-subnet-2"
  resource_group_name  = azurerm_resource_group.client-uscentral.name
  virtual_network_name = azurerm_virtual_network.client-uscentral-vnet.name
  address_prefixes       = ["10.100.20.128/25"]
}

#######################################################################
## Create public-IP - client SEA
#######################################################################
resource "azurerm_public_ip" "client-uscentral-pip" {
name                = "client-uscentral-pip"
location            = var.location-client-uscentral
resource_group_name = azurerm_resource_group.client-uscentral.name
allocation_method   = "Dynamic"
tags = {
    environment = "client-uscentral"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}


#######################################################################
## Create Network Interface - client SEA
#######################################################################
resource "azurerm_network_interface" "client-uscentral-nic1" {
  name                 = "client-uscentral-nic1"
  location             = var.location-client-uscentral
  resource_group_name  = azurerm_resource_group.client-uscentral.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "client-uscentral-ipconfig"
    subnet_id                     = azurerm_subnet.client-uscentral-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.client-uscentral-pip.id
  }

  tags = {
    environment = "client-uscentral"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}


resource "azurerm_network_security_group" "client-uscentral-nsg"{
    name = "client-uscentral-nsg"
    location             = var.location-client-uscentral
    resource_group_name  = azurerm_resource_group.client-uscentral.name

   
##    security_rule {
##    name                       = "http"
##    priority                   = 200
##    direction                  = "Inbound"
##    access                     = "Allow"
##    protocol                   = "Tcp"
##    source_port_range          = "*"
##    destination_port_range     = "80"
##    source_address_prefix      = "*"
##    destination_address_prefix = "*"
##    }
##    security_rule {
##    name                       = "https"
##    priority                   = 210
##    direction                  = "Inbound"
##    access                     = "Allow"
##    protocol                   = "Tcp"
##    source_port_range          = "*"
##    destination_port_range     = "443"
##    source_address_prefix      = "*"
##    destination_address_prefix = "*"
##    }

    security_rule {
    name                       = "RDP"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = chomp(data.http.myip-usc.body)
    destination_address_prefix = "*"
    }

    security_rule {
    name                       = "icmp"
    priority                   = 230
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "ICMP"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }

    tags = {
      environment = "client-uscentral"
      deployment  = "terraform"
      microhack    = "frontdoor"
    }
}
## resource "azurerm_network_interface" "nva-iptables-vm-nic-1" {
##   name                 = "nva-iptables-vm-nic-1"
##   location             = var.location-spoke-services
##   resource_group_name  = azurerm_resource_group.vwan-microhack-spoke-rg.name
##   enable_ip_forwarding = true
##   ip_configuration {
##     name                          = "nva-1-ipconfig"
##     subnet_id                     = azurerm_subnet.nva-subnet-1.id
##     private_ip_address_allocation = "Static"
##     private_ip_address = "172.16.20.4"
##     public_ip_address_id = azurerm_public_ip.nva-iptables-vm-pub-ip.id
##   }
##   tags = {
##     environment = "nva"
##     deployment  = "terraform"
##     microhack    = "vwan"
##   }
## }
resource "azurerm_subnet_network_security_group_association" "client-uscentral-nsg-ass" {
  subnet_id      = azurerm_subnet.client-uscentral-subnet-1.id
  network_security_group_id = azurerm_network_security_group.client-uscentral-nsg.id
 }

#######################################################################
## Create Virtual Machine spoke-1
#######################################################################

resource "azurerm_windows_virtual_machine" "client-uscentral-vm" {
  name                  = "mh-clt-USC-vm1"
  depends_on = [ azurerm_key_vault.kv1 ]
  location              = var.location-client-uscentral
  resource_group_name   = azurerm_resource_group.client-uscentral.name
  network_interface_ids = [azurerm_network_interface.client-uscentral-nic1.id]
  size               = var.vmsize-windows
  computer_name  = "mh-clt-USC-vm1"
  admin_username = var.username
  # admin_password = var.password
  admin_password      = azurerm_key_vault_secret.vmpassword.value
  provision_vm_agent = true

  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    name              = "spoke-1-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  
  tags = {
    environment = "client-uscentral-vm"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}
## #######################################################################
## ## Create Virtual Machine spoke-2
## #######################################################################
## resource "azurerm_windows_virtual_machine" "spoke-2-vm" {
##   name                  = "spoke-2-vm"
##   location              = var.location-spoke-2
##   resource_group_name   = azurerm_resource_group.vwan-microhack-spoke-rg.name
##   network_interface_ids = [azurerm_network_interface.spoke-2-nic.id]
##   size               = var.vmsize
##   computer_name  = "spoke-2-vm"
##   admin_username = var.username
##   admin_password = var.password
##   provision_vm_agent = true
##   
## 
##   source_image_reference {
##     offer     = "WindowsServer"
##     publisher = "MicrosoftWindowsServer"
##     sku       = "2019-Datacenter"
##     version   = "latest"
##   }
## 
##   os_disk {
##     name              = "spoke-2-osdisk"
##     caching           = "ReadWrite"
##     storage_account_type = "StandardSSD_LRS"
##   }
## 
##   tags = {
##     environment = "spoke-2"
##     deployment  = "terraform"
##     microhack    = "vwan"
##   }
## }
## #######################################################################
## ## Create Virtual Machine spoke-3
## #######################################################################
## resource "azurerm_windows_virtual_machine" "spoke-3-vm" {
##   name                  = "spoke-3-vm"
##   location              = var.location-spoke-3
##   resource_group_name   = azurerm_resource_group.vwan-microhack-spoke-rg.name
##   network_interface_ids = [azurerm_network_interface.spoke-3-nic.id]
##   size               = var.vmsize
##   computer_name  = "spoke-3-vm"
##   admin_username = var.username
##   admin_password = var.password
##   provision_vm_agent = true
## 
##   source_image_reference {
##     offer     = "WindowsServer"
##     publisher = "MicrosoftWindowsServer"
##     sku       = "2019-Datacenter"
##     version   = "latest"
##   }
## 
##   os_disk {
##     name              = "spoke-3-osdisk"
##     caching           = "ReadWrite"
##     storage_account_type = "StandardSSD_LRS"
##   }
## 
##   tags = {
##     environment = "spoke-3"
##     deployment  = "terraform"
##     microhack    = "vwan"
##   }
## }
## #######################################################################
## ## Create Virtual Machine spoke-4
## #######################################################################
## resource "azurerm_windows_virtual_machine" "spoke-4-vm" {
##   name                  = "spoke-4-vm"
##   location              = var.location-spoke-4
##   resource_group_name   = azurerm_resource_group.vwan-microhack-spoke-rg.name
##   network_interface_ids = [azurerm_network_interface.spoke-4-nic.id]
##   size               = var.vmsize
##   computer_name  = "spoke-4-vm"
##   admin_username = var.username
##   admin_password = var.password
##   provision_vm_agent = true
## 
##   source_image_reference {
##     offer     = "WindowsServer"
##     publisher = "MicrosoftWindowsServer"
##     sku       = "2019-Datacenter"
##     version   = "latest"
##   }
## 
##   os_disk {
##     name              = "spoke-4-osdisk"
##     caching           = "ReadWrite"
##     storage_account_type = "StandardSSD_LRS"
##   }
## 
##   tags = {
##     environment = "spoke-4"
##     deployment  = "terraform"
##     microhack    = "vwan"
##   }
## }
## #######################################################################
## ## Create Virtual Machine onprem
## #######################################################################
## resource "azurerm_windows_virtual_machine" "onprem-vm" {
##   name                  = "onprem-vm"
##   location              = var.location-onprem
##   resource_group_name   = azurerm_resource_group.vwan-microhack-spoke-rg.name
##   network_interface_ids = [azurerm_network_interface.onprem-nic.id]
##   size               = var.vmsize
##   computer_name  = "onprem-vm"
##   admin_username = var.username
##   admin_password = var.password
##   provision_vm_agent = true
## 
##   source_image_reference {
##     offer     = "WindowsServer"
##     publisher = "MicrosoftWindowsServer"
##     sku       = "2019-Datacenter"
##     version   = "latest"
##   }
## 
##   os_disk {
##     name              = "onprem-osdisk"
##     caching           = "ReadWrite"
##     storage_account_type = "StandardSSD_LRS"
##   }
## 
##   tags = {
##     environment = "onprem"
##     deployment  = "terraform"
##     microhack    = "vwan"
##   }
## }
## #######################################################################
## ## Create Virtual Machine spoke-addc
## #######################################################################
## resource "azurerm_windows_virtual_machine" "spoke-addc-vm" {
##   name                  = "spoke-addc-vm"
##   location              = var.location-spoke-services
##   resource_group_name   = azurerm_resource_group.vwan-microhack-spoke-rg.name
##   network_interface_ids = [azurerm_network_interface.spoke-addc-1-nic.id]
##   size               = var.vmsize
##   computer_name  = "spoke-addc-vm"
##   admin_username = var.username
##   admin_password = var.password
##   provision_vm_agent = true
## 
##   source_image_reference {
##     offer     = "WindowsServer"
##     publisher = "MicrosoftWindowsServer"
##     sku       = "2019-Datacenter"
##     version   = "latest"
##   }
## 
##   os_disk {
##     name              = "spoke-addc-osdisk"
##     caching           = "ReadWrite"
##     storage_account_type = "StandardSSD_LRS"
##   }
## 
##   tags = {
##     environment = "addc"
##     deployment  = "terraform"
##     microhack    = "vwan"
##   }
## }
## #######################################################################
## ## Create Network Interface - nva-iptables-vm
## #######################################################################
## resource "azurerm_public_ip" "nva-iptables-vm-pub-ip"{
##     name                 = "nva-iptables-vm-pub-ip"
##     location             = var.location-spoke-services
##     resource_group_name  = azurerm_resource_group.vwan-microhack-spoke-rg.name
##     allocation_method   = "Static"
##     tags = {
##       environment = "nva"
##       deployment  = "terraform"
##       microhack    = "vwan"
##     }
## }
## resource "azurerm_network_security_group" "nva-iptables-vm-nsg"{
##     name = "nva-iptables-vm-nsg"
##     location             = var.location-spoke-services
##     resource_group_name  = azurerm_resource_group.vwan-microhack-spoke-rg.name
## 
##    
##     security_rule {
##     name                       = "http"
##     priority                   = 200
##     direction                  = "Inbound"
##     access                     = "Allow"
##     protocol                   = "Tcp"
##     source_port_range          = "*"
##     destination_port_range     = "80"
##     source_address_prefix      = "*"
##     destination_address_prefix = "*"
##     }
##     security_rule {
##     name                       = "https"
##     priority                   = 210
##     direction                  = "Inbound"
##     access                     = "Allow"
##     protocol                   = "Tcp"
##     source_port_range          = "*"
##     destination_port_range     = "443"
##     source_address_prefix      = "*"
##     destination_address_prefix = "*"
##     }
##     security_rule {
##     name                       = "icmp"
##     priority                   = 220
##     direction                  = "Inbound"
##     access                     = "Allow"
##     protocol                   = "Tcp"
##     source_port_range          = "*"
##     destination_port_range     = "*"
##     source_address_prefix      = "*"
##     destination_address_prefix = "*"
##     }
## 
##     tags = {
##       environment = "nva"
##       deployment  = "terraform"
##       microhack    = "vwan"
##     }
## }
## resource "azurerm_network_interface" "nva-iptables-vm-nic-1" {
##   name                 = "nva-iptables-vm-nic-1"
##   location             = var.location-spoke-services
##   resource_group_name  = azurerm_resource_group.vwan-microhack-spoke-rg.name
##   enable_ip_forwarding = true
##   ip_configuration {
##     name                          = "nva-1-ipconfig"
##     subnet_id                     = azurerm_subnet.nva-subnet-1.id
##     private_ip_address_allocation = "Static"
##     private_ip_address = "172.16.20.4"
##     public_ip_address_id = azurerm_public_ip.nva-iptables-vm-pub-ip.id
##   }
##   tags = {
##     environment = "nva"
##     deployment  = "terraform"
##     microhack    = "vwan"
##   }
## }
## resource "azurerm_subnet_network_security_group_association" "nva-iptables-vm-nsg-ass" {
##   subnet_id      = azurerm_subnet.nva-subnet-1.id
##   network_security_group_id = azurerm_network_security_group.nva-iptables-vm-nsg.id
## }
## 
## #######################################################################
## ## Create Virtual Machine - NVA
## #######################################################################
## resource "azurerm_linux_virtual_machine" "nva-iptables-vm" {
##   name                  = "nva-iptables-vm"
##   location              = var.location-spoke-services
##   resource_group_name   = azurerm_resource_group.vwan-microhack-spoke-rg.name
##   network_interface_ids = [azurerm_network_interface.nva-iptables-vm-nic-1.id]
##   size               = var.vmsize
##   admin_username = var.username
##   admin_password = var.password
##   disable_password_authentication = false
## 
##   source_image_reference {
##     publisher = "Canonical"
##     offer     = "UbuntuServer"
##     sku       = "18.04-LTS"
##     version   = "latest"
##   }
## 
##   os_disk {
##     name              = "nva-iptables-vm-osdisk"
##     caching           = "ReadWrite"
##     storage_account_type = "StandardSSD_LRS"
##   }  
## 
##   tags = {
##     environment = "nva"
##     deployment  = "terraform"
##     microhack    = "vwan"
##   }
## }