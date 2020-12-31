terraform {
  required_version = "=0.14.3"
  required_providers {
    helm       = "=1.3.2"
    kubernetes = "=1.13.3"
  }
}

provider "helm" {
  kubernetes {
    load_config_file       = "false"
    host                   = var.host
    client_certificate     = var.client_certificate
    client_key             = var.client_key
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

module "ingress-nginx" {
  source = "../ingress-nginx"
}

module "prometheus" {
  source = "../prometheus"
}

//resource "helm_release" "kubeapps" {
//  chart = "kubeapps"
//  name = "kubeapps"
//  repository = "https://charts.bitnami.com/bitnami"
//  namespace = "kubeapps"
//  create_namespace = true
//}

//resource "helm_release" "postgresql" {
//  chart = "postgresql"
//  name = "den-postgresql"
//  repository = "https://charts.bitnami.com/bitnami"
//
//  set {
//    name = "postgresqlDatabase"
//    value = "orchardcore_database"
//  }
//
//  set {
//    name = "postgresqlPassword"
//    value = "PrmcEy71kg"
//  }
//}