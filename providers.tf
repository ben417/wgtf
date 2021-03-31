terraform {
  required_providers {
    azurerm = {
      version = ">= 2.53.0"
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}