terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  required_version = ">=0.12"
}
