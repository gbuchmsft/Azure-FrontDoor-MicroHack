#output "azurerm_storage_account_blob_endpoint" {
#    value = azurerm_storage_account.storagesea.primary_blob_endpoint
#}
#
#output "azurerm_storage_account_web_endpoint" {
#    value = azurerm_storage_account.storagesea.primary_web_endpoint
#}

output "Storage_in_SEA" {
    value = "https://${azurerm_storage_account.storagesea.primary_web_host}"
}

output "Storage_in_USC" {
    value = "https://${azurerm_storage_account.storageusc.primary_web_host}"
}

output "Storage_in_WEU" {
    value = "https://${azurerm_storage_account.storageweu.primary_web_host}"
}
output "Virtual_Machine-SEA" {
    value = azurerm_windows_virtual_machine.client-southeastasia-vm.public_ip_address
}

output "Virtual_Machine-USC" {
    value = azurerm_windows_virtual_machine.client-uscentral-vm.public_ip_address
}

output "Virtual_Machine-WEU" {
    value = azurerm_windows_virtual_machine.client-westeurope-vm.public_ip_address
}

output "VM-Webserver-SEA" {
    value = azurerm_linux_virtual_machine.mh-sea-web-vm-1.public_ip_address
}

output "Virtual_Machine-USC-PW" {
    value = nonsensitive(azurerm_key_vault_secret.vmpassword.value)
}


output "AzureFrontDoorNameCNAME" {
    value = azurerm_frontdoor.frontdoorstd.cname
}


output "AzureFrontDoorName" {
    value = azurerm_frontdoor.frontdoorstd.name
}

output "AzureVM-WEU-fqdn" {
    value = azurerm_public_ip.client-westeurope-pip.fqdn
}

output "Webserver_SEA" {
    value = azurerm_public_ip.mh-sea-web-vm1-pip.fqdn
}

output "Webserver_WEU" {
    value = azurerm_public_ip.mh-weu-web-vm1-pip.fqdn
}

output "Webserver_USC" {
    value = azurerm_public_ip.mh-usc-web-vm1-pip.fqdn
}