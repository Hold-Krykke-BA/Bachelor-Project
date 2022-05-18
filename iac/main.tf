terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.6.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rr-dev-rg" {
  name     = var.rg_name
  location = var.location
}

module "network" {
  source   = "./modules/network"
  rg_name  = azurerm_resource_group.rr-dev-rg.name
  location = azurerm_resource_group.rr-dev-rg.location
}

module "services" {
  source                      = "./modules/services"
  rg_name                     = azurerm_resource_group.rr-dev-rg.name
  location                    = azurerm_resource_group.rr-dev-rg.location
  aks_location                = var.aks_location
  storage_account             = module.storage.storage_account_rr0dev0sa1
  ingress_application_gateway = module.network.application_gateway_rr_dev_agw
}

module "storage" {
  source         = "./modules/storage"
  rg_name        = azurerm_resource_group.rr-dev-rg.name
  location       = azurerm_resource_group.rr-dev-rg.location
  sql_location   = var.sql_location
  mssql_username = var.mssql_username
  mssql_password = var.mssql_password
}