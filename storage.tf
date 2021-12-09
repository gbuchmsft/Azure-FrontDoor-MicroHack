#######################################################################
## Create random ID for storage account
#######################################################################

resource "random_id" "randomIdStorage" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = var.rg-pl-vm-backend
    }

    byte_length = 8
}

#######################################################################
## Create storage account with random ID WEU
#######################################################################


resource "azurerm_storage_account" "storageweu" {
    depends_on = [ azurerm_resource_group.rg-storageaccount ]
    name                        = "weu${random_id.randomIdStorage.hex}"
    resource_group_name         = var.rg-storageaccount
    
    location                    = var.location-storagaccount1
    account_replication_type    = "LRS"
    account_tier                = "Standard"
    account_kind                = "StorageV2"

    static_website {
    index_document = "index-weu.html"
    }

 tags = {
    environment = "Lab"
    deployment  = "terraform"
    feature = "StorageAccountWithWebEnabled"
  }
}

resource "azurerm_storage_blob" "staticWebsite" {
  name                   = "index-weu.html"
  storage_account_name   = azurerm_storage_account.storageweu.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "index-weu.html"
}

#######################################################################
## Create storage account with random ID USC
#######################################################################


resource "azurerm_storage_account" "storageusc" {
    depends_on = [ azurerm_resource_group.rg-storageaccount ]
    name                        = "usc${random_id.randomIdStorage.hex}"
    resource_group_name         = var.rg-storageaccount
    
    location                    = var.location-storagaccount2
    account_replication_type    = "LRS"
    account_tier                = "Standard"
    account_kind                = "StorageV2"

    static_website {
    index_document = "index-usc.html"
    }

 tags = {
    environment = "Lab"
    deployment  = "terraform"
    feature = "StorageAccountWithWebEnabled"
  }
}

resource "azurerm_storage_blob" "staticWebsiteusc" {
  name                   = "index-usc.html"
  storage_account_name   = azurerm_storage_account.storageusc.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "index-usc.html"
}

#######################################################################
## Create storage account with random ID SEA
#######################################################################


resource "azurerm_storage_account" "storagesea" {
    depends_on = [ azurerm_resource_group.rg-storageaccount ]
    name                        = "sea${random_id.randomIdStorage.hex}"
    resource_group_name         = var.rg-storageaccount
    
    location                    = var.location-storagaccount3
    account_replication_type    = "LRS"
    account_tier                = "Standard"
    account_kind                = "StorageV2"

    static_website {
    index_document = "index-sea.html"
    }

 tags = {
    environment = "Lab"
    deployment  = "terraform"
    feature = "StorageAccountWithWebEnabled"
  }
}

resource "azurerm_storage_blob" "staticWebsitesea" {
  name                   = "index-sea.html"
  storage_account_name   = azurerm_storage_account.storagesea.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "index-sea.html"
}