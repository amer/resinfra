terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.23.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.37.0"
    }
  }
  required_version = ">=0.12"
}
