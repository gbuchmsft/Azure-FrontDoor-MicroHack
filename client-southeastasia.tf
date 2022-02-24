#######################################################################
## Get Data like public IP from location
#######################################################################
data "http" "myip-sea" {
  url = "https://api.ipify.org/"
}

#######################################################################
## Create Virtual Network - client SouthEastAsia
## PrivateLink Backend
#######################################################################

resource "azurerm_virtual_network" "client-southeastasia-vnet" {
  name                = "client-southeastasia-vnet"
  location            = var.location-client-southeastasia
  resource_group_name = azurerm_resource_group.client-southeastasia.name
  address_space       = ["10.100.10.0/23"]

  tags = {
    environment = "client-southeastasia"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

#######################################################################
## Create Subnets - client SEA
#######################################################################

resource "azurerm_subnet" "client-southeastasia-subnet-1" {
  name                 = "client-southeastasia-subnet-1"
  resource_group_name  = azurerm_resource_group.client-southeastasia.name
  virtual_network_name = azurerm_virtual_network.client-southeastasia-vnet.name
  address_prefixes       = ["10.100.10.0/25"]
}
resource "azurerm_subnet" "client-southeastasia-subnet-2" {
  name                 = "client-southeastasia-subnet-2"
  resource_group_name  = azurerm_resource_group.client-southeastasia.name
  virtual_network_name = azurerm_virtual_network.client-southeastasia-vnet.name
  address_prefixes       = ["10.100.10.128/25"]
}


#######################################################################
## Create public-IP - client SEA
#######################################################################
resource "azurerm_public_ip" "client-southeastasia-pip" {
name                = "client-southeastasia-pip"
location            = var.location-client-southeastasia
resource_group_name = azurerm_resource_group.client-southeastasia.name
allocation_method   = "Dynamic"
tags = {
    environment = "client-southeastasia"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

#######################################################################
## Create Network Interface - client SEA
#######################################################################

resource "azurerm_network_interface" "client-southeastasia-nic1" {
  name                 = "client-southeastasia-nic1"
  location             = var.location-client-southeastasia
  resource_group_name  = azurerm_resource_group.client-southeastasia.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "client-southeastasia-ipconfig"
    subnet_id                     = azurerm_subnet.client-southeastasia-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.client-southeastasia-pip.id
  }

  tags = {
    environment = "client-southeastasia"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}


resource "azurerm_network_security_group" "client-southeastasia-nsg"{
    name = "client-southeastasia-nsg"
    location             = var.location-client-southeastasia
    resource_group_name  = azurerm_resource_group.client-southeastasia.name

    security_rule {
    name                       = "RDP"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    #source_address_prefix      = "${chomp(data.http.myip-sea.body)}"
    source_address_prefix      = chomp(data.http.myip-sea.body)
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
      environment = "client-southeastasia"
      deployment  = "terraform"
      microhack    = "frontdoor"
    }
}

resource "azurerm_subnet_network_security_group_association" "client-southeastasia-nsg-ass" {
  subnet_id      = azurerm_subnet.client-southeastasia-subnet-1.id
  network_security_group_id = azurerm_network_security_group.client-southeastasia-nsg.id
 }

#######################################################################
## Create Virtual Machine spoke-1
#######################################################################

resource "azurerm_windows_virtual_machine" "client-southeastasia-vm" {
  name                  = "mh-clt-SEA-vm1"
  location              = var.location-client-southeastasia
  resource_group_name   = azurerm_resource_group.client-southeastasia.name
  network_interface_ids = [azurerm_network_interface.client-southeastasia-nic1.id]
  size               = var.vmsize-windows
  computer_name  = "mh-clt-SEA-vm1"
  admin_username = var.username
  admin_password = azurerm_key_vault_secret.vmpassword.value
  enable_automatic_updates = true
  patch_mode = "AutomaticByOS"
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
    environment = "client-southeastasia-vm"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

# Generate randon name for virtual machine
resource "random_string" "random-win-vm" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  number  = true
}

# Virtual Machine Extension to Install IIS
resource "azurerm_virtual_machine_extension" "iis-windows-vm-extension" {
  depends_on=[azurerm_windows_virtual_machine.client-southeastasia-vm]  
  name = "win-${random_string.random-win-vm.result}-vm-extension"
  virtual_machine_id = azurerm_windows_virtual_machine.client-southeastasia-vm.id
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
