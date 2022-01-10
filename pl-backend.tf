#######################################################################
## Create random ID for storage account
#######################################################################

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = var.rg-pl-vm-backend
    }

    byte_length = 8
}

#######################################################################
## Create storage account with random ID
#######################################################################


resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = var.rg-pl-vm-backend
    location                    = "eastus"
    account_replication_type    = "LRS"
    account_tier                = "Standard"
    depends_on = [
      azurerm_virtual_network.pl-backend-vnet
    ]

 tags = {
    environment = "frontdoor"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

#######################################################################
## Create Virtual Network - pl-backend
## PrivateLink Backend
#######################################################################

resource "azurerm_virtual_network" "pl-backend-vnet" {
  name                = "pl-backend-vnet"
  location            = var.location-pl-backend-eastus
  resource_group_name = var.rg-pl-vm-backend
  address_space       = ["10.34.0.0/20"]
  depends_on = [
      azurerm_resource_group.frontdoor-pl-backend-eastus
    ]

  tags = {
    environment = "pl-backend-eastus"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

#######################################################################
## Create Subnets - Spoke 1
#######################################################################

resource "azurerm_subnet" "frontdoor-pl-backend-eastus-subnet-1" {
  name                 = "frontdoor-pl-backend-eastus-subnet-1"
  resource_group_name  = var.rg-pl-vm-backend
  virtual_network_name = azurerm_virtual_network.pl-backend-vnet.name
  address_prefixes       = ["10.34.1.0/25"]
}
resource "azurerm_subnet" "frontdoor-pl-backend-eastus-subnet-2" {
  name                 = "frontdoor-pl-backend-eastus-subnet-2"
  resource_group_name  = var.rg-pl-vm-backend
  virtual_network_name = azurerm_virtual_network.pl-backend-vnet.name
  address_prefixes       = ["10.34.1.128/25"]
}

#######################################################################
## Create VM1
#######################################################################

#######################################################################
## Create Network Interface - pl-backend
#######################################################################

resource "azurerm_network_interface" "pl-backend-vm-1-nic" {
  name                 = "pl-backend-vm-1-nic"
  location             = var.location-pl-backend-eastus
  resource_group_name  = var.rg-pl-vm-backend
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "pl-backend-vm-1-ipconfig"
    subnet_id                     = azurerm_subnet.frontdoor-pl-backend-eastus-subnet-1.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "pl-backend-eastus"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

#######################################################################
## Create Virtual Machine spoke-1
#######################################################################

resource "azurerm_linux_virtual_machine" "pl-backend-vm-1" {
  name                  = "pl-backend-vm-1"
  location              = var.location-pl-backend-eastus
  resource_group_name   = var.rg-pl-vm-backend
  network_interface_ids = [azurerm_network_interface.pl-backend-vm-1-nic.id]
  size               = var.vmsize
  computer_name  = "pl-backend-vm-1"
  disable_password_authentication = false
  admin_username = var.username
  admin_password = var.password
  # custom_data    = data.template_file.user_data.rendered
  custom_data    = filebase64("pl-backend-cloudinit.yaml")
  provision_vm_agent = true

    source_image_reference {
            publisher = "Canonical"
            offer     = "UbuntuServer"
            sku       = "18.04-LTS"
            version   = "latest"
    }

    os_disk {
        name              = "pl-backend-vm-1-osdisk"
        caching           = "ReadWrite"
        storage_account_type = "StandardSSD_LRS"
    }

    boot_diagnostics {
                storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
            }
    
    tags = {
        environment = "pl-backend-eastus"
        deployment  = "terraform"
        microhack    = "frontdoor"
    }
}

#######################################################################
## Create VM2
#######################################################################

#######################################################################
## Create Network Interface - pl-backend
#######################################################################

resource "azurerm_network_interface" "pl-backend-vm-2-nic" {
  name                 = "pl-backend-vm-2-nic"
  location             = var.location-pl-backend-eastus
  resource_group_name  = var.rg-pl-vm-backend
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "pl-backend-vm-2-ipconfig"
    subnet_id                     = azurerm_subnet.frontdoor-pl-backend-eastus-subnet-1.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "pl-backend-eastus"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}

#######################################################################
## Create Virtual Machine spoke-1
#######################################################################

resource "azurerm_linux_virtual_machine" "pl-backend-vm-2" {
  name                  = "pl-backend-vm-2"
  location              = var.location-pl-backend-eastus
  resource_group_name   = var.rg-pl-vm-backend
  network_interface_ids = [azurerm_network_interface.pl-backend-vm-2-nic.id]
  size               = var.vmsize
  computer_name  = "pl-backend-vm-2"
  disable_password_authentication = false
  admin_username = var.username
  admin_password = var.password
  provision_vm_agent = true

    source_image_reference {
            publisher = "Canonical"
            offer     = "UbuntuServer"
            sku       = "18.04-LTS"
            version   = "latest"
        }

    os_disk {
            name              = "pl-backend-vm-2-osdisk"
            caching           = "ReadWrite"
            storage_account_type = "StandardSSD_LRS"
        }

    boot_diagnostics {
            storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
        }
    
    tags = {
        environment = "pl-backend-eastus"
        deployment  = "terraform"
        microhack    = "frontdoor"
    }
}


#######################################################################
## Create internal loadbalancer
#######################################################################
# 
# resource "azurerm_lb" "azlb" {
#   name                = local.lb_name
#   resource_group_name = data.azurerm_resource_group.azlb.name
#   location            = coalesce(var.location, data.azurerm_resource_group.azlb.location)
#   sku                 = var.lb_sku
#   tags                = var.tags
# 
#   frontend_ip_configuration {
#     name                          = var.frontend_name
#     public_ip_address_id          = var.type == "public" ? join("", azurerm_public_ip.azlb.*.id) : ""
#     subnet_id                     = var.frontend_subnet_id
#     private_ip_address            = var.frontend_private_ip_address
#     private_ip_address_allocation = var.frontend_private_ip_address_allocation
#   }
# }



# resource "azurerm_public_ip" "example" {
#   name                = "PublicIPForLB"
#   location            = "West US"
#   resource_group_name = azurerm_resource_group.example.name
#   allocation_method   = "Static"
# }

resource "azurerm_lb" "internal-lb" {
  name                = "TestLoadBalancer"
  location            = "eastus"
  resource_group_name = var.rg-pl-vm-backend
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "FrontEndPrivIP"
  #  public_ip_address_id = azurerm_public_ip.internal-lb.id
    subnet_id            = azurerm_subnet.frontdoor-pl-backend-eastus-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version = "IPv4"
  }
}


resource "azurerm_lb_backend_address_pool" "http-pool" {
  # resource_group_name = var.rg-pl-vm-backend
  loadbalancer_id     = azurerm_lb.internal-lb.id
  name                = "http-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "web" {
  network_interface_id    = azurerm_network_interface.pl-backend-vm-1-nic.id
  ip_configuration_name   = "pl-backend-vm-1-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.http-pool.id
}

resource "azurerm_network_interface_backend_address_pool_association" "web2" {
  network_interface_id    = azurerm_network_interface.pl-backend-vm-2-nic.id
  ip_configuration_name   = "pl-backend-vm-2-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.http-pool.id
}

resource "azurerm_lb_probe" "web" {
  resource_group_name = var.rg-pl-vm-backend
  loadbalancer_id     = azurerm_lb.internal-lb.id
  name                = "web-running-probe"
  port                = 80
}

resource "azurerm_lb_rule" "web" {
  resource_group_name            = var.rg-pl-vm-backend
  loadbalancer_id                = azurerm_lb.internal-lb.id
  name                           = "web-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "FrontEndPrivIP"
  probe_id                       = azurerm_lb_probe.web.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.http-pool.id]
}


## data "azurerm_linux_virtual_machine" "pl-backend-vm-2" {
##   name                = "pl-backend-vm-2"
##   resource_group_name = var.rg-pl-vm-backend
## }

## data "azurerm_storage_account" "mystorageaccount" {
##  name                = "mystorageaccount"
##  resource_group_name = var.rg-pl-vm-backend
## }
## 
## resource "azurerm_monitor_diagnostic_setting" "AzDiagnosticsPLBackEnd" {
##   name               = "AzDiagnosticsPLBackEnd"
##   target_resource_id = data.azurerm_linux_virtual_machine.pl-backend-vm-2.name
##   storage_account_id = data.azurerm_storage_account.mystorageaccount.id
## 
##   log {
##     category = "AuditEvent"
##     enabled  = false
## 
##     retention_policy {
##       enabled = false
##     }
##   }
## 
##   metric {
##     category = "AllMetrics"
## 
##     retention_policy {
##       enabled = false
##     }
##   }
## }