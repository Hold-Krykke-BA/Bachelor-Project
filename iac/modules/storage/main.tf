resource "azurerm_storage_account" "rr0dev0sa1" {
  name                     = "rr0dev0sa1"
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "rr-dev-sa1-blob" {
  name                  = "rr-dev-sa1-blob"
  storage_account_name  = azurerm_storage_account.rr0dev0sa1.name
  container_access_type = "blob"
}

resource "azurerm_mssql_server" "rr-dev-mssql-server" {
  name                         = "rr-dev-mssql-server"
  resource_group_name          = var.rg_name
  location                     = var.sql_location
  version                      = "12.0"
  administrator_login          = var.mssql_username
  administrator_login_password = var.mssql_password
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_elasticpool" "rr-dev-mssql-epool" {
  name                = "rr-dev-mssql-epool"
  resource_group_name = var.rg_name
  location            = var.sql_location
  server_name         = azurerm_mssql_server.rr-dev-mssql-server.name
  license_type        = "LicenseIncluded"
  max_size_gb         = 500

  sku {
    name     = "StandardPool"
    tier     = "Standard"
    capacity = 50
  }

  per_database_settings {
    min_capacity = 0
    max_capacity = 10
  }
}

resource "azurerm_mssql_database" "rr-dev-mssql-db" {
  name            = "rr-dev-mssql-db"
  server_id       = azurerm_mssql_server.rr-dev-mssql-server.id
  collation       = "SQL_Latin1_General_CP1_CI_AS"
  license_type    = "LicenseIncluded"
  sku_name        = "ElasticPool"
  elastic_pool_id = azurerm_mssql_elasticpool.rr-dev-mssql-epool.id
}