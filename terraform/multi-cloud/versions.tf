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
    template = {
      source = "hashicorp/template"
      version = "~> 2.2.0"
    }
     proxmox = {
      source = "Telmate/proxmox"
      version = "~> 2.6.5"
    }
  }
  required_version = ">=0.13.5"
}
