terraform {
  required_version = "=0.14.2"
  required_providers {
    helm = "=1.3.2"
  }
}

provider "helm" {
  kubernetes {
    host                   = var.host
    client_certificate     = var.client_certificate
    client_key             = var.client_key
    cluster_ca_certificate = var.client_certificate
  }
}
