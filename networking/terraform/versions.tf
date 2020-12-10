terraform {
  required_providers {
    /*
    aws = {
      source  = "hashicorp/aws"
    }*/
    azurerm = {
      source = "hashicorp/azurerm"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">=0.12"
}
