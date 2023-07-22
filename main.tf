terraform {
  required_version = "~>1.4.6"
  required_providers {
    azurrem {
        source ="hashicorp/azurerm"
        version=">~2.52.0"
    }
  }
}

provider "azurerm" {
    features{}
    skip_provider_registration = true
}

resource "azurerm_resource_group" "rg" {
    name = "my-teff123"
    location = "East US"

}