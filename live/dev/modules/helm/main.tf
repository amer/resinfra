terraform {
  required_version = "=0.14.2"
  required_providers {
    helm = "=1.3.2"
    kubernetes = "=1.13.3"
  }
}
provider "helm" {
  kubernetes {
    load_config_file = "false"
    host = var.host
    client_certificate = var.client_certificate
    client_key = var.client_key
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

provider "kubernetes" {
  load_config_file = "false"
  host = var.host
  client_certificate = var.client_certificate
  client_key = var.client_key
  cluster_ca_certificate = var.cluster_ca_certificate
}



resource "helm_repository" "prometheus-community" {
  name = "prometheus-community "
  url = "https://prometheus-community.github.io/helm-charts"
}

resource "helm_repository" "stable" {
  name = "stable"
  url = "https://charts.helm.sh/stable"
}
resource "helm_release" "prometheus" {
  chart = "prometheus-community/kube-prometheus-stack"
  name = "ri-prometheus"
}
