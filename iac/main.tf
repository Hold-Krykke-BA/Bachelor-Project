# Configure the Azure provider
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

resource "azurerm_resource_group" "rr_dev_rg" {
  name     = "rr_dev_rg"
  location = var.location
}

resource "azurerm_app_service_plan" "rr_dev_sp" {
  name                = "rr_dev_sp"
  resource_group_name = azurerm_resource_group.rr_dev_rg.name
  location            = azurerm_resource_group.rr_dev_rg.location

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_windows_web_app" "rr_dev_web_app" {
  name                = "rr-dev-web-app"
  resource_group_name = azurerm_resource_group.rr_dev_rg.name
  location            = azurerm_app_service_plan.rr_dev_sp.location
  service_plan_id     = azurerm_app_service_plan.rr_dev_sp.id

  site_config {}
}

# resource "azurerm_api_management" "rr_dev_api_mgmt" {
#   name                = "rr_dev_api_mgmt"
#   location            = azurerm_resource_group.rr_dev_rg.location
#   resource_group_name = azurerm_resource_group.rr_dev_rg.name
#   publisher_name      = "Rights and Royalty"
#   publisher_email     = "bachelor.holdkrykke@gmail.com"

#   sku_name = "Developer_1"
# }

resource "azurerm_public_ip" "rr_dev_lb_ip" {
  name                = "rr_dev_lb_ip"
  location            = azurerm_resource_group.rr_dev_rg.location
  resource_group_name = azurerm_resource_group.rr_dev_rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "rr_dev_lb" {
  name                = "rr_dev_lb"
  location            = azurerm_resource_group.rr_dev_rg.location
  resource_group_name = azurerm_resource_group.rr_dev_rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.rr_dev_lb_ip.id
  }
}


###########################
resource "azurerm_public_ip" "rr_dev_agw_ip" {
  name                = "rr_dev_agw_ip"
  location            = azurerm_resource_group.rr_dev_rg.location
  resource_group_name = azurerm_resource_group.rr_dev_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network" "rr_dev_vnet" {
  name                = "rr_dev_vnet"
  location            = azurerm_resource_group.rr_dev_rg.location
  resource_group_name = azurerm_resource_group.rr_dev_rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_subnet" "rr_dev_subnet1" {
  name                 = "rr_dev_subnet1"
  resource_group_name  = azurerm_resource_group.rr_dev_rg.name
  virtual_network_name = azurerm_virtual_network.rr_dev_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "rr_dev_subnet2" {
  name                 = "rr_dev_subnet2"
  resource_group_name  = azurerm_resource_group.rr_dev_rg.name
  virtual_network_name = azurerm_virtual_network.rr_dev_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

locals {
  subnet2_address_pool_name   = "${azurerm_virtual_network.rr_dev_vnet.name}-se2ap"
  subnet1_port_name           = "${azurerm_virtual_network.rr_dev_vnet.name}-se1port"
  subnet1_ip_conf_name        = "${azurerm_virtual_network.rr_dev_vnet.name}-se1ip"
  http_setting_name           = "${azurerm_virtual_network.rr_dev_vnet.name}-be-htst"
  listener_name               = "${azurerm_virtual_network.rr_dev_vnet.name}-httplstn"
  request_routing_rule_name   = "${azurerm_virtual_network.rr_dev_vnet.name}-rqrt"
  redirect_configuration_name = "${azurerm_virtual_network.rr_dev_vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "rr_dev_agw" {
  name                = "rr_dev_agw"
  resource_group_name = azurerm_resource_group.rr_dev_rg.name
  location            = azurerm_resource_group.rr_dev_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "rr_dev_agw_ip_conf"
    subnet_id = azurerm_subnet.rr_dev_subnet1.id
  }

  frontend_port {
    name = local.subnet1_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.subnet1_ip_conf_name
    public_ip_address_id = azurerm_public_ip.rr_dev_agw_ip.id
  }

  backend_address_pool {
    name = local.subnet2_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name = local.listener_name

    frontend_ip_configuration_name = local.subnet1_ip_conf_name
    frontend_port_name             = local.subnet1_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    priority                   = 1
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.subnet2_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}


###########################



resource "azurerm_kubernetes_cluster" "rr_dev_aks" {
  name                = "rr_dev_aks"
  location            = "germanywestcentral" #azurerm_resource_group.rr_dev_rg.location
  resource_group_name = azurerm_resource_group.rr_dev_rg.name
  dns_prefix          = "rrdevaks"


  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "standard_f2s_v2" #"Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.rr_dev_agw.id
    #gateway_name = azurerm_application_gateway.rr_dev_agw.name
    #subnet_id    = azurerm_subnet.rr_dev_subnet1.id
    #subnet_cidr  = azurerm_subnet.rr_dev_subnet1.address_prefixes[0]
  }
}

#######################
resource "azurerm_servicebus_namespace" "rr-dev-bus" {
  name                = "rr-dev-bus-17052022"
  location            = azurerm_resource_group.rr_dev_rg.location
  resource_group_name = azurerm_resource_group.rr_dev_rg.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "rr_dev_bus_queue" {
  name         = "rr_dev_bus_queue"
  namespace_id = azurerm_servicebus_namespace.rr-dev-bus.id

  enable_partitioning = true
}

resource "azurerm_servicebus_topic" "rr_dev_bus_topic" {
  name         = "rr_dev_bus_topic"
  namespace_id = azurerm_servicebus_namespace.rr-dev-bus.id

  enable_partitioning = true
}

########################


resource "azurerm_storage_account" "rr0dev0sa1" {
  name                     = "rr0dev0sa1"
  resource_group_name      = azurerm_resource_group.rr_dev_rg.name
  location                 = azurerm_resource_group.rr_dev_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# resource "azurerm_app_service_plan" "rr_dev_asp" {
#   name                = "azure-functions-test-service-plan"
#   location            = azurerm_resource_group.rr_dev_rg.location
#   resource_group_name = azurerm_resource_group.rr_dev_rg.name

#   sku {
#     tier = "Standard"
#     size = "S1"
#   }
# }

resource "azurerm_windows_function_app" "rr-dev-fna-jobs" {
  name                       = "rr-dev-fna-jobs"
  location                   = azurerm_resource_group.rr_dev_rg.location
  resource_group_name        = azurerm_resource_group.rr_dev_rg.name
  service_plan_id            = azurerm_app_service_plan.rr_dev_sp.id
  storage_account_name       = azurerm_storage_account.rr0dev0sa1.name
  storage_account_access_key = azurerm_storage_account.rr0dev0sa1.primary_access_key

  site_config {}
}

###########################

resource "azurerm_storage_container" "rr-dev-sa1-blob" {
  name                  = "rr-dev-sa1-blob"
  storage_account_name  = azurerm_storage_account.rr0dev0sa1.name
  container_access_type = "blob"
}


###########################

resource "azurerm_mssql_server" "rr-dev-mssql-server" {
  name                         = "rr-dev-mssql-server"
  resource_group_name          = azurerm_resource_group.rr_dev_rg.name
  location                     = "germanywestcentral" # azurerm_resource_group.rr_dev_rg.location
  version                      = "12.0"
  administrator_login          = "missadministrator" #todo variable
  administrator_login_password = "thisIsKat11"       #todo variable
  minimum_tls_version          = "1.2"

}

resource "azurerm_mssql_elasticpool" "rr-dev-mssql-epool" {
  name                = "rr-dev-mssql-epool"
  resource_group_name = azurerm_resource_group.rr_dev_rg.name
  location            = "germanywestcentral" # azurerm_resource_group.rr_dev_rg.location
  server_name         = azurerm_mssql_server.rr-dev-mssql-server.name
  license_type        = "LicenseIncluded"
  max_size_gb         = 500

  sku {
    name = "StandardPool"
    tier = "Standard"
    # family   = "Gen4"
    capacity = 50 #todo work out a proper number
  }

  per_database_settings {
    min_capacity = 0  #todo work out a proper number
    max_capacity = 10 #todo work out a proper number
  }
}

resource "azurerm_mssql_database" "rr-dev-mssql-db" {
  name         = "rr-dev-mssql-db"
  server_id    = azurerm_mssql_server.rr-dev-mssql-server.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  #   max_size_gb  = 4
  #   read_scale   = true
  sku_name = "ElasticPool"
  #   zone_redundant = true
  elastic_pool_id = azurerm_mssql_elasticpool.rr-dev-mssql-epool.id
}

