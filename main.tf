  provider "azurerm" {
    features {}
  }

  #######################################################################
  #######################################################################
  ## Create Resource Groups
  #######################################################################
  #######################################################################
  resource "azurerm_resource_group" "frontdoor" {
    name     = var.rg-frontdoor
    location = var.location-frontdoor
  tags = {
      environment = "frontdoor"
      deployment  = "terraform"
      microhack    = "frontdoor"
    }
  }

  #######################################################################
  ## Important : AFD Premium Preview with PrivateLink Endpoint is only available in:
  ## East US, South Central US, West US 2, UK South, Japan East
  #######################################################################
  resource "azurerm_resource_group" "frontdoor-pl-backend-eastus" {
    name     = var.rg-pl-vm-backend
    location = var.location-pl-backend-eastus
  tags = {
      environment = "pl-backend-eastus"
      deployment  = "terraform"
      microhack    = "frontdoor"
    }
  }

  #######################################################################
  ## Resource group for windows client in SouthEastAsia
  #######################################################################
  resource "azurerm_resource_group" "client-southeastasia" {
    name     = "client-southeastasia"
    location = var.location-client-southeastasia
  tags = {
      environment = "client-southeastasia"
      deployment  = "terraform"
      microhack    = "frontdoor"
    }
  }

  #######################################################################
  ## Resource group for windows client in USCentral
  #######################################################################
  resource "azurerm_resource_group" "client-uscentral" {
    name     = "client-uscentral"
    location = var.location-client-uscentral
  tags = {
      environment = "client-uscentral"
      deployment  = "terraform"
      microhack    = "frontdoor"
    }
  }

  #######################################################################
  ## Resource group for windows client in Westeurope
  #######################################################################
  resource "azurerm_resource_group" "client-westeurope" {
    name     = "client-westeurope"
    location = var.location-client-westeurope
  tags = {
      environment = "client-westeurope"
      deployment  = "terraform"
      microhack    = "frontdoor"
    }
  }

  resource "azurerm_resource_group" "rg-storageaccount" {
    name     = var.rg-storageaccount
    location = var.location-storagaccount1
  tags = {
      environment = "storageaccount"
      deployment  = "terraform"
      microhack    = "frontdoor"
    }
  }

  #######################################################################
  ## Resource group for webserver in different regions
  #######################################################################

  resource "azurerm_resource_group" "rg-webserver" {
    name     = "FD-MH-webserver"
    location = "SouthEastAsia"
  tags = {
      environment = "webserver"
      deployment  = "terraform"
      microhack    = "frontdoor"
    }
  }

  #######################################################################
  # Generate randon 4 digit number for this lab
  #######################################################################
  resource "random_string" "random-number-lab" {
    length  = 4
    special = false
    lower   = false
    upper   = false
    number  = true
  }

  #data "template_file" "user_data" {
  #  template = file("pl-backend-cloudinit.yaml")
  #}
  #
  #data "template_cloudinit_config" "config" {
  #  gzip          = false
  #  base64_encode = false
  #
  #part {
  #    content_type = "text/cloud-init"
  #    content      = data.template_file.user_data.rendered
  #  }
  #}