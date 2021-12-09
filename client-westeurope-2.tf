#######################################################################
## Get Data like public IP from location
#######################################################################
data "http" "myip-weu-2" {
  url = "https://api.ipify.org/"
}

#######################################################################
# Generate randon 4 digit string to be used in this module
#######################################################################
resource "random_string" "random-win-vm-WEU-2" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  number  = true
}


#######################################################################
## Create Virtual Network - client WestEurope
## PrivateLink Backend
#######################################################################

resource "azurerm_virtual_network" "client-westeurope-vnet-2" {
  name                = "client-westeurope-vnet-2"
  location            = var.location-client-westeurope
  resource_group_name = azurerm_resource_group.client-westeurope.name
  address_space       = ["10.100.4.0/23","fd00:db8:deca:daed::/64"]

  tags = {
    environment = "client-westeurope-2"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

#######################################################################
## Create Subnets - client WestEurope
#######################################################################

resource "azurerm_subnet" "client-westeurope-2-subnet-1" {
  name                 = "client-westeurope-2-subnet-1"
  resource_group_name  = azurerm_resource_group.client-westeurope.name
  virtual_network_name = azurerm_virtual_network.client-westeurope-vnet-2.name
  address_prefixes       = ["10.100.4.0/25","fd00:db8:deca:daed::/64"]
}
## resource "azurerm_subnet" "client-westeurope-2-subnet-2" {
##   name                 = "client-westeurope-2-subnet-2"
##   resource_group_name  = azurerm_resource_group.client-westeurope.name
##   virtual_network_name = azurerm_virtual_network.client-westeurope-vnet-2.name
##   address_prefixes       = ["10.100.4.128/25"]
## }


#######################################################################
## Create public-IP - client WestEurope
#######################################################################
resource "azurerm_public_ip" "client-westeurope-pip-2" {
depends_on          = [random_string.random-number-lab]
name                = "client-westeurope-2-pip"
location            = var.location-client-westeurope
sku                 = "Standard"
resource_group_name = azurerm_resource_group.client-westeurope.name
allocation_method   = "Static"
ip_version = "IPv4"
domain_name_label   = "cltweu2-${random_string.random-number-lab.result}"
tags = {
    environment = "client-westeurope-2"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

resource "azurerm_public_ip" "client-westeurope-pip-2-v6" {
depends_on          = [random_string.random-number-lab]
name                = "client-westeurope-2-pip-2"
location            = var.location-client-westeurope
sku                 = "Standard"
resource_group_name = azurerm_resource_group.client-westeurope.name
allocation_method   = "Static"
ip_version = "IPv6"
domain_name_label   = "cltweu2-${random_string.random-number-lab.result}"
tags = {
    environment = "client-westeurope-2"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}


#depends_on=[azurerm_windows_virtual_machine.client-westeurope-vm]  
#  name = "win-${random_string.random-win-vm-WEU.result}-vm-extension"

#######################################################################
## Create Network Interface - client WestEurope
#######################################################################

resource "azurerm_network_interface" "client-westeurope-2-nic1" {
  name                 = "client-westeurope-2-nic1"
  location             = var.location-client-westeurope
  resource_group_name  = azurerm_resource_group.client-westeurope.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "client-westeurope-ipconfig-2"
    subnet_id                     = azurerm_subnet.client-westeurope-2-subnet-1.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Dynamic"
    primary                       = "true"
    public_ip_address_id          = azurerm_public_ip.client-westeurope-pip-2.id
  }

  ip_configuration {
    name                          = "client-westeurope-ipconfig-3"
    subnet_id                     = azurerm_subnet.client-westeurope-2-subnet-1.id
    private_ip_address_version    = "IPv6"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.client-westeurope-pip-2-v6.id
  }

  tags = {
    environment = "client-westeurope-2"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}


resource "azurerm_network_security_group" "client-westeurope-2-nsg"{
    name = "client-westeurope-2-nsg"
    location             = var.location-client-westeurope
    resource_group_name  = azurerm_resource_group.client-westeurope.name

    security_rule {
    name                       = "RDP"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = chomp(data.http.myip-weu-2.body)
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
      environment = "client-westeurope-2"
      deployment  = "terraform"
      microhack    = "frontdoor"
    }
}

resource "azurerm_subnet_network_security_group_association" "client-westeurope-2-nsg-ass" {
  subnet_id      = azurerm_subnet.client-westeurope-2-subnet-1.id
  network_security_group_id = azurerm_network_security_group.client-westeurope-2-nsg.id
 }

#######################################################################
## Create Virtual Machine spoke-1
#######################################################################

resource "azurerm_windows_virtual_machine" "client-westeurope-2-vm" {
  name                  = "mh-clt-WEU-vm2"
  depends_on = [ azurerm_key_vault.kv1 ]
  location              = var.location-client-westeurope
  resource_group_name   = azurerm_resource_group.client-westeurope.name
  network_interface_ids = [azurerm_network_interface.client-westeurope-2-nic1.id]
  size               = var.vmsize-windows
  computer_name  = "mh-clt-WEU-vm2"
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
    name              = "spoke-1-osdisk-2"
    caching           = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  
  tags = {
    environment = "client-westeurope-2"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

# Virtual Machine Extension to Install IIS
resource "azurerm_virtual_machine_extension" "iis-windows-vm-extension-WEU-2" {
  depends_on=[azurerm_windows_virtual_machine.client-westeurope-2-vm]  
  name = "win-${random_string.random-win-vm-WEU-2.result}-vm-extension"
  virtual_machine_id = azurerm_windows_virtual_machine.client-westeurope-2-vm.id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.9"  
  settings = <<SETTINGS
    { 
      "commandToExecute": "powershell Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    } 
  SETTINGS
  }
  # Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
