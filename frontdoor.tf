resource "random_id" "randomIdFDStd" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = var.rg-pl-vm-backend
    }

    byte_length = 4
}


resource "azurerm_frontdoor" "frontdoorstd" {
    depends_on                                   = [ azurerm_storage_account.storageweu ]
    name                                         = "${var.frontdoorstdname}${random_id.randomIdFDStd.hex}"
    #location                                     = var.frontdoorstdlocation
    #location                                      = "global"
    resource_group_name                          = var.rg-frontdoor
    enforce_backend_pools_certificate_name_check = false

  routing_rule {
    name               = "Routing-Rule-1"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["examplefrontendpoint1"]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "Backend-Storage"
    }
  }

  backend_pool_load_balancing {
    name = "exampleLoadBalancingSettings1"
  }

  backend_pool_health_probe {
    name = "exampleHealthProbeSetting1"
  }

  backend_pool {
    name = "Backend-Storage"
    backend {
      host_header = azurerm_storage_account.storagesea.primary_web_host
      address     = azurerm_storage_account.storagesea.primary_web_host
      http_port   = 80
      https_port  = 443
    }
    
    backend {
      host_header = azurerm_storage_account.storageusc.primary_web_host
      address     = azurerm_storage_account.storageusc.primary_web_host
      http_port   = 80
      https_port  = 443
    }
    
    backend {
      host_header = azurerm_storage_account.storageweu.primary_web_host
      address     = azurerm_storage_account.storageweu.primary_web_host
      http_port   = 80
      https_port  = 443
    }

   # backend {
   #   host_header = azurerm_linux_virtual_machine.mh-sea-web-vm-1.public_ip_address
   #   address = azurerm_linux_virtual_machine.mh-sea-web-vm-1.public_ip_address
   #   http_port = 80
   #   https_port  = 443
   # }

    load_balancing_name = "exampleLoadBalancingSettings1"
    health_probe_name   = "exampleHealthProbeSetting1"
  }

  backend_pool {
    name = "Backend-Webserver"
    backend {
      host_header = azurerm_public_ip.mh-sea-web-vm1-pip.fqdn
      address     = azurerm_public_ip.mh-sea-web-vm1-pip.fqdn
      http_port   = 80
      https_port  = 443
    }
    
    backend {
      host_header = azurerm_public_ip.mh-usc-web-vm1-pip.fqdn
      address     = azurerm_public_ip.mh-usc-web-vm1-pip.fqdn
      http_port   = 80
      https_port  = 443
    }
    
    backend {
      host_header = azurerm_public_ip.mh-weu-web-vm1-pip.fqdn
      address     = azurerm_public_ip.mh-weu-web-vm1-pip.fqdn
      http_port   = 80
      https_port  = 443
    }

   # backend {
   #   host_header = azurerm_linux_virtual_machine.mh-sea-web-vm-1.public_ip_address
   #   address = azurerm_linux_virtual_machine.mh-sea-web-vm-1.public_ip_address
   #   http_port = 80
   #   https_port  = 443
   # }

    load_balancing_name = "exampleLoadBalancingSettings1"
    health_probe_name   = "exampleHealthProbeSetting1"
  }

  frontend_endpoint {
    name      = "examplefrontendpoint1"
    host_name = "${var.frontdoorstdname}${random_id.randomIdFDStd.hex}.azurefd.net"
  }
}

# Log Analytice Workspace to ingest Log used during MicroHack
resource "azurerm_log_analytics_workspace" "loganalytics" {
  name                = "log${random_id.randomIdFDStd.hex}"
  location            = azurerm_resource_group.frontdoor.location
  resource_group_name = azurerm_resource_group.frontdoor.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azurerm_monitor_diagnostic_setting" "EnableDiagnostics" {
  name                        = "EnableDiagnostics"
  target_resource_id          = azurerm_frontdoor.frontdoorstd.id
  storage_account_id          = azurerm_storage_account.storageweu.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.loganalytics.id

  log {
    category = "FrontdoorAccessLog"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

    log {
    category = "FrontdoorWebApplicationFirewallLog"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}