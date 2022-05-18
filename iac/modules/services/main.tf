resource "azurerm_app_service_plan" "rr-dev-asp" {
  name                = "rr-dev-asp"
  resource_group_name = var.rg_name
  location            = var.location

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_windows_web_app" "rr-dev-web-app" {
  name                = "rr-dev-web-app"
  resource_group_name = var.rg_name
  location            = azurerm_app_service_plan.rr-dev-asp.location
  service_plan_id     = azurerm_app_service_plan.rr-dev-asp.id

  site_config {}
}

resource "azurerm_windows_function_app" "rr-dev-fna-jobs" {
  name                       = "rr-dev-fna-jobs"
  location                   = var.location
  resource_group_name        = var.rg_name
  service_plan_id            = azurerm_app_service_plan.rr-dev-asp.id
  storage_account_name       = var.storage_account.name
  storage_account_access_key = var.storage_account.primary_access_key

  site_config {}
}

###############################

resource "azurerm_kubernetes_cluster" "rr-dev-aks" {
  name                = "rr-dev-aks"
  location            = var.aks_location
  resource_group_name = var.rg_name
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
    gateway_id = var.ingress_application_gateway.id
  }
}

#######################
resource "azurerm_servicebus_namespace" "rr-dev-bus" {
  name                = "rr-dev-bus-17052022"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "rr-dev-bus-queue" {
  name         = "rr-dev-bus-queue"
  namespace_id = azurerm_servicebus_namespace.rr-dev-bus.id

  enable_partitioning = true
}

resource "azurerm_servicebus_topic" "rr-dev-bus-topic" {
  name         = "rr-dev-bus-topic"
  namespace_id = azurerm_servicebus_namespace.rr-dev-bus.id

  enable_partitioning = true
}