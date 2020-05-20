#Terraform version
###
#terraform {
#	required_version = "> 0.12.6"
#	required_providers {
#	  azurerm = "1.44.0"
#}
#}
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}

    subscription_id = ""
	client_id = ""
	client_secret = ""
	tenant_id = ""
}

