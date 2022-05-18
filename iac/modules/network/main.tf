resource "azurerm_virtual_network" "rr-dev-vnet" {
  name                = "rr-dev-vnet"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_subnet" "rr-dev-subnet1" {
  name                 = "rr-dev-subnet1"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.rr-dev-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "rr-dev-subnet2" {
  name                 = "rr-dev-subnet2"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.rr-dev-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "rr-dev-lb-ip" {
  name                = "rr-dev-lb-ip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
}

resource "azurerm_lb" "rr-dev-lb" {
  name                = "rr-dev-lb"
  location            = var.location
  resource_group_name = var.rg_name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.rr-dev-lb-ip.id
  }
}

resource "azurerm_public_ip" "rr-dev-agw-ip" {
  name                = "rr-dev-agw-ip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

locals {
  subnet2_address_pool_name   = "${azurerm_virtual_network.rr-dev-vnet.name}-se2ap"
  subnet1_port_name           = "${azurerm_virtual_network.rr-dev-vnet.name}-se1port"
  subnet1_ip_conf_name        = "${azurerm_virtual_network.rr-dev-vnet.name}-se1ip"
  http_setting_name           = "${azurerm_virtual_network.rr-dev-vnet.name}-be-htst"
  listener_name               = "${azurerm_virtual_network.rr-dev-vnet.name}-httplstn"
  request_routing_rule_name   = "${azurerm_virtual_network.rr-dev-vnet.name}-rqrt"
  redirect_configuration_name = "${azurerm_virtual_network.rr-dev-vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "rr-dev-agw" {
  name                = "rr-dev-agw"
  resource_group_name = var.rg_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "rr-dev-agw-ip-conf"
    subnet_id = azurerm_subnet.rr-dev-subnet1.id
  }

  frontend_port {
    name = local.subnet1_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.subnet1_ip_conf_name
    public_ip_address_id = azurerm_public_ip.rr-dev-agw-ip.id
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