# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}

    subscription_id = "0b97f93e-03fa-49ab-a749-a10c33756e8e"
	client_id = "1a724262-f67f-47c0-8e7b-e2c4cc6ee02b"
	client_secret = "88bed221-c527-40b5-a90a-3968e0466be3"
	tenant_id = "59783927-d29f-4be3-aa7b-29aaf737b343"

}
##Manages app gateway
resource "azurerm_resource_group" "MDSAppgtw" {
  name     = "MDSAppgtw-resources"
  location = "West US"
}

resource "azurerm_virtual_network" "MDSVnet" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.MDSAppgtw.name
  location            = azurerm_resource_group.MDSAppgtw.location
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.MDSAppgtw.name
  virtual_network_name = azurerm_virtual_network.MDSVnet.name
  address_prefix       = "10.254.0.0/24"
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.MDSAppgtw.name
  virtual_network_name = azurerm_virtual_network.MDSVnet.name
  address_prefix       = "10.254.2.0/24"
}

resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  resource_group_name = azurerm_resource_group.MDSAppgtw.name
  location            = azurerm_resource_group.MDSAppgtw.location
  allocation_method   = "Dynamic"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "azurerm_virtual_network.MDSVnet.name-beap"
  frontend_port_name             = "azurerm_virtual_network.MDSVnet.name-feport"
  frontend_ip_configuration_name = "azurerm_virtual_network.MDSVnet.name-feip"
  http_setting_name              = "azurerm_virtual_network.MDSVnet.name-be-htst"
  listener_name                  = "azurerm_virtual_network.MDSVnet.name-httplstn"
  request_routing_rule_name      = "azurerm_virtual_network.MDSVnet.name-rqrt"
  redirect_configuration_name    = "azurerm_virtual_network.MDSVnet.name-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "MDS-appgateway"
  resource_group_name = azurerm_resource_group.MDSAppgtw.name
  location            = azurerm_resource_group.MDSAppgtw.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}


## Application Gateway's can be imported using the resource id, e.g.

#terraform import azurerm_application_gateway.example /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mygroup1/providers/Microsoft.Network/applicationGateways/myGateway1
#Intro