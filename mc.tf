terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id   = ${env.ARM_SUBSCRIPTION_ID}
  tenant_id         = ${env.ARM_TENANT_ID}
  client_id         = ${env.ARM_CLIENT_ID}
  client_secret     = ${env.ARM_CLIENT_SECRET}
}

# Your code goes here
