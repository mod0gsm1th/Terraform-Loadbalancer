variable "name" {
    type = string
    description = "Name of the system or environment"
}
variable "location" {
    type = string
    description = "Azure location of terraform server environment"
    default = "westus2"

resource "azurerm_resource_group" "MDSLB" {
  name     = "MDSLoadBalancerRG"
  location = "West US"
}

resource "azurerm_storage_account" "MDSFAStor" {
  name                     = "functionsappstor"
  resource_group_name      = azurerm_resource_group.MDSLB.name
  location                 = azurerm_resource_group.MDSLB.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "MDSSVCP" {
  name                = "azure-functions-test-service-plan"
  location            = azurerm_resource_group.MDSLB.location
  resource_group_name = azurerm_resource_group.MDSLB.name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "MDSFA" {
  name                      = "test-azure-functions"
  location                  = azurerm_resource_group.MDSLB.location
  resource_group_name       = azurerm_resource_group.MDSLB.name
  app_service_plan_id       = azurerm_app_service_plan.MDSSVCP.id
  storage_connection_string = azurerm_storage_account.MDSFAStor.primary_connection_string
}
»