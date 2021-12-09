#######################################################################
## Get Data like public IP from location
#######################################################################
data "http" "myip-web-sea" {
  url = "https://api.ipify.org/"
}

#######################################################################
## Create Webserver with NginX in SouthEastAsia
#######################################################################


#######################################################################
## Create Virtual Network SouthEastAsia
#######################################################################

resource "azurerm_virtual_network" "mh-sea-web-vnet" {
  name                = "mh-sea-web-vnet"
  location            = "SouthEastAsia"
  resource_group_name = azurerm_resource_group.rg-webserver.name
  address_space       = ["10.200.10.0/23"]
  depends_on = [
      azurerm_resource_group.rg-webserver
    ]

  tags = var.resource_tags
}

#######################################################################
## Create Subnets -SouthEastAsia
#######################################################################

resource "azurerm_subnet" "mh-sea-web-subnet-1" {
  name                 = "mh-sea-web-subnet-1"
  resource_group_name  = azurerm_resource_group.rg-webserver.name
  virtual_network_name = azurerm_virtual_network.mh-sea-web-vnet.name
  address_prefixes       = ["10.200.10.0/25"]
}
resource "azurerm_subnet" "mh-sea-web-subnet-2" {
  name                 = "mh-sea-web-subnet-2"
  resource_group_name  = azurerm_resource_group.rg-webserver.name
  virtual_network_name = azurerm_virtual_network.mh-sea-web-vnet.name
  address_prefixes       = ["10.200.10.128/25"]
}

#######################################################################
## Create VM1
#######################################################################

#######################################################################
## Create public-IP - webserver SEA
#######################################################################
resource "azurerm_public_ip" "mh-sea-web-vm1-pip" {
name                = "mh-sea-web-vm1-pip"
location            = "SouthEastAsia"
resource_group_name = azurerm_resource_group.rg-webserver.name
allocation_method   = "Dynamic"
#domain_name_label  = "vm-${random_string.random-number-lab.id}test.southeastasia.cloudapp.azure.com"
domain_name_label  = "vm-${random_string.random-number-lab.id}test-sea"
tags = var.resource_tags
}

#######################################################################
## Create Network Interface
#######################################################################

resource "azurerm_network_interface" "mh-sea-web-vm-1-nic" {
  name                 = "mh-sea-web-vm-1-nic"
  location             = "SouthEastAsia"
  resource_group_name  = azurerm_resource_group.rg-webserver.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "mh-sea-web-vm-1-ipconfig"
    subnet_id                     = azurerm_subnet.mh-sea-web-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mh-sea-web-vm1-pip.id
  }

  tags = var.resource_tags
}

#######################################################################
## Create Virtual Machine spoke-1
#######################################################################

resource "azurerm_linux_virtual_machine" "mh-sea-web-vm-1" {
  name                  = "mh-sea-web-vm-1"
  location              = "SouthEastAsia"
  resource_group_name   = azurerm_resource_group.rg-webserver.name
  network_interface_ids = [azurerm_network_interface.mh-sea-web-vm-1-nic.id]
  size               = var.vmsize
  computer_name  = "mh-sea-web-vm-1"
  disable_password_authentication = false
  admin_username = var.username
  admin_password = azurerm_key_vault_secret.vmpassword.value
  # custom_data    = data.template_file.user_data.rendered
  custom_data    = filebase64("./resources/mh-sea-web-vm-cloudinit.yaml")
  provision_vm_agent = true

    source_image_reference {
            publisher = "Canonical"
            offer     = "UbuntuServer"
            sku       = "18.04-LTS"
            version   = "latest"
    }

    os_disk {
        name              = "mh-sea-web-vm-1-osdisk"
        caching           = "ReadWrite"
        storage_account_type = "StandardSSD_LRS"
    }

    boot_diagnostics {
                storage_account_uri = azurerm_storage_account.storagesea.primary_blob_endpoint
            }
    
    tags = var.resource_tags
 }

 resource "azurerm_network_security_group" "mh-sea-web-vm-1-nsg"{
    name = "mh-sea-web-vm-1-nsg"
    location             = "SouthEastAsia"
    resource_group_name  = azurerm_resource_group.rg-webserver.name

    security_rule {
    name                       = "SSH"
    priority                   = 215
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    #source_address_prefix      = "${chomp(data.http.myip-sea.body)}"
    source_address_prefix      = chomp(data.http.myip-web-sea.body)
    destination_address_prefix = "*"
    }
    
    security_rule {
    name                       = "HTTP"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    #source_address_prefix      = chomp(data.http.myip-web-sea.body)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }

    security_rule {
    name                       = "HTTPS"
    priority                   = 225
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    #source_address_prefix      = chomp(data.http.myip-web-sea.body)
    source_address_prefix      = "*"
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

    tags = var.resource_tags
}

resource "azurerm_subnet_network_security_group_association" "mh-sea-web-vm-1-nsg-ass" {
  subnet_id      = azurerm_subnet.mh-sea-web-subnet-1.id
  network_security_group_id = azurerm_network_security_group.mh-sea-web-vm-1-nsg.id
 }



#######################################################################
## Create Webserver with NginX in WestEurope
#######################################################################


#######################################################################
## Create Virtual Network WestEurope
#######################################################################

resource "azurerm_virtual_network" "mh-weu-web-vnet" {
  name                = "mh-weu-web-vnet"
  location            = "WestEurope"
  resource_group_name = azurerm_resource_group.rg-webserver.name
  address_space       = ["10.200.0.0/23"]
  depends_on = [
      azurerm_resource_group.rg-webserver
    ]

  tags = var.resource_tags
}

#######################################################################
## Create Subnets -SouthEastAsia
#######################################################################

resource "azurerm_subnet" "mh-weu-web-subnet-1" {
  name                 = "mh-weu-web-subnet-1"
  resource_group_name  = azurerm_resource_group.rg-webserver.name
  virtual_network_name = azurerm_virtual_network.mh-weu-web-vnet.name
  address_prefixes       = ["10.200.0.0/25"]
}
resource "azurerm_subnet" "mh-weu-web-subnet-2" {
  name                 = "mh-weu-web-subnet-2"
  resource_group_name  = azurerm_resource_group.rg-webserver.name
  virtual_network_name = azurerm_virtual_network.mh-weu-web-vnet.name
  address_prefixes       = ["10.200.0.128/25"]
}

#######################################################################
## Create VM1
#######################################################################

#######################################################################
## Create public-IP - webserver SEA
#######################################################################
resource "azurerm_public_ip" "mh-weu-web-vm1-pip" {
name                = "mh-weu-web-vm1-pip"
location            = "WestEurope"
resource_group_name = azurerm_resource_group.rg-webserver.name
allocation_method   = "Dynamic"
#domain_name_label  = "vm-${random_string.random-number-lab.id}test.southeastasia.cloudapp.azure.com"
domain_name_label  = "vm-${random_string.random-number-lab.id}test-weu"
tags = var.resource_tags
}

#######################################################################
## Create Network Interface
#######################################################################

resource "azurerm_network_interface" "mh-weu-web-vm-1-nic" {
  name                 = "mh-weu-web-vm-1-nic"
  location             = "WestEurope"
  resource_group_name  = azurerm_resource_group.rg-webserver.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "mh-weu-web-vm-1-ipconfig"
    subnet_id                     = azurerm_subnet.mh-weu-web-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mh-weu-web-vm1-pip.id
  }

  tags = var.resource_tags
}

#######################################################################
## Create Virtual Machine spoke-1
#######################################################################

resource "azurerm_linux_virtual_machine" "mh-weu-web-vm-1" {
  name                  = "mh-weu-web-vm-1"
  location              = "WestEurope"
  resource_group_name   = azurerm_resource_group.rg-webserver.name
  network_interface_ids = [azurerm_network_interface.mh-weu-web-vm-1-nic.id]
  size               = var.vmsize
  computer_name  = "mh-weu-web-vm-1"
  disable_password_authentication = false
  admin_username = var.username
  admin_password = azurerm_key_vault_secret.vmpassword.value
  # custom_data    = data.template_file.user_data.rendered
  custom_data    = filebase64("./resources/mh-sea-web-vm-cloudinit.yaml")
  provision_vm_agent = true

    source_image_reference {
            publisher = "Canonical"
            offer     = "UbuntuServer"
            sku       = "18.04-LTS"
            version   = "latest"
    }

    os_disk {
        name              = "mh-weu-web-vm-1-osdisk"
        caching           = "ReadWrite"
        storage_account_type = "StandardSSD_LRS"
    }

    boot_diagnostics {
                storage_account_uri = azurerm_storage_account.storageweu.primary_blob_endpoint
            }
    
    tags = var.resource_tags
}
 resource "azurerm_network_security_group" "mh-weu-web-vm-1-nsg"{
    name = "mh-weu-web-vm-1-nsg"
    location             = "WestEurope"
    resource_group_name  = azurerm_resource_group.rg-webserver.name
    
    security_rule {
    name                       = "SSH"
    priority                   = 215
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    #source_address_prefix      = "${chomp(data.http.myip-sea.body)}"
    source_address_prefix      = chomp(data.http.myip-web-sea.body)
    destination_address_prefix = "*"
    }
    
    security_rule {
    name                       = "HTTP"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    #source_address_prefix      = chomp(data.http.myip-web-sea.body)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }

    security_rule {
    name                       = "HTTPS"
    priority                   = 225
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    #source_address_prefix      = chomp(data.http.myip-web-sea.body)
    source_address_prefix      = "*"
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

    tags = var.resource_tags
 }

resource "azurerm_subnet_network_security_group_association" "mh-weu-web-vm-1-nsg-ass" {
  subnet_id      = azurerm_subnet.mh-weu-web-subnet-1.id
  network_security_group_id = azurerm_network_security_group.mh-weu-web-vm-1-nsg.id
 }


 #######################################################################
## Create Webserver with NginX in US Central
#######################################################################


#######################################################################
## Create Virtual Network US Central
#######################################################################

resource "azurerm_virtual_network" "mh-usc-web-vnet" {
  name                = "mh-usc-web-vnet"
  location            = "CentralUS"
  resource_group_name = azurerm_resource_group.rg-webserver.name
  address_space       = ["10.200.0.0/23"]
  depends_on = [
      azurerm_resource_group.rg-webserver
    ]

  tags = var.resource_tags
}

#######################################################################
## Create Subnets -SouthEastAsia
#######################################################################

resource "azurerm_subnet" "mh-usc-web-subnet-1" {
  name                 = "mh-usc-web-subnet-1"
  resource_group_name  = azurerm_resource_group.rg-webserver.name
  virtual_network_name = azurerm_virtual_network.mh-usc-web-vnet.name
  address_prefixes       = ["10.200.0.0/25"]
}
resource "azurerm_subnet" "mh-usc-web-subnet-2" {
  name                 = "mh-usc-web-subnet-2"
  resource_group_name  = azurerm_resource_group.rg-webserver.name
  virtual_network_name = azurerm_virtual_network.mh-usc-web-vnet.name
  address_prefixes       = ["10.200.0.128/25"]
}

#######################################################################
## Create VM1
#######################################################################

#######################################################################
## Create public-IP - webserver SEA
#######################################################################
resource "azurerm_public_ip" "mh-usc-web-vm1-pip" {
name                = "mh-usc-web-vm1-pip"
location            = "CentralUS"
resource_group_name = azurerm_resource_group.rg-webserver.name
allocation_method   = "Dynamic"
#domain_name_label  = "vm-${random_string.random-number-lab.id}test.southeastasia.cloudapp.azure.com"
domain_name_label  = "vm-${random_string.random-number-lab.id}test-usc"
tags = var.resource_tags
}

#######################################################################
## Create Network Interface
#######################################################################

resource "azurerm_network_interface" "mh-usc-web-vm-1-nic" {
  name                 = "mh-usc-web-vm-1-nic"
  location             = "CentralUS"
  resource_group_name  = azurerm_resource_group.rg-webserver.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "mh-usc-web-vm-1-ipconfig"
    subnet_id                     = azurerm_subnet.mh-usc-web-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mh-usc-web-vm1-pip.id
  }

  tags = var.resource_tags
}

#######################################################################
## Create Virtual Machine spoke-1
#######################################################################

resource "azurerm_linux_virtual_machine" "mh-usc-web-vm-1" {
  name                  = "mh-usc-web-vm-1"
  location              = "CentralUS"
  resource_group_name   = azurerm_resource_group.rg-webserver.name
  network_interface_ids = [azurerm_network_interface.mh-usc-web-vm-1-nic.id]
  size               = var.vmsize
  computer_name  = "mh-usc-web-vm-1"
  disable_password_authentication = false
  admin_username = var.username
  admin_password = azurerm_key_vault_secret.vmpassword.value
  # custom_data    = data.template_file.user_data.rendered
  custom_data    = filebase64("./resources/mh-sea-web-vm-cloudinit.yaml")
  provision_vm_agent = true

    source_image_reference {
            publisher = "Canonical"
            offer     = "UbuntuServer"
            sku       = "18.04-LTS"
            version   = "latest"
    }

    os_disk {
        name              = "mh-usc-web-vm-1-osdisk"
        caching           = "ReadWrite"
        storage_account_type = "StandardSSD_LRS"
    }

    boot_diagnostics {
                storage_account_uri = azurerm_storage_account.storageusc.primary_blob_endpoint
            }
    
    tags = var.resource_tags
}
 resource "azurerm_network_security_group" "mh-usc-web-vm-1-nsg"{
    name = "mh-usc-web-vm-1-nsg"
    location             = "CentralUS"
    resource_group_name  = azurerm_resource_group.rg-webserver.name

    security_rule {
    name                       = "SSH"
    priority                   = 215
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    #source_address_prefix      = "${chomp(data.http.myip-sea.body)}"
    source_address_prefix      = chomp(data.http.myip-web-sea.body)
    destination_address_prefix = "*"
    }
    
    security_rule {
    name                       = "HTTP"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    #source_address_prefix      = chomp(data.http.myip-web-sea.body)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }

    security_rule {
    name                       = "HTTPS"
    priority                   = 225
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    #source_address_prefix      = chomp(data.http.myip-web-sea.body)
    source_address_prefix      = "*"
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

    tags = var.resource_tags
 }

resource "azurerm_subnet_network_security_group_association" "mh-usc-web-vm-1-nsg-ass" {
  subnet_id      = azurerm_subnet.mh-usc-web-subnet-1.id
  network_security_group_id = azurerm_network_security_group.mh-usc-web-vm-1-nsg.id
 }