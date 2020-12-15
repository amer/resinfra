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

resource "helm_release" "prometheus" {
  name = "ri-prometheus"
  chart = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace = "monitoring"
  create_namespace = true
}

resource "helm_release" "nginx-stable" {
  name = "ri-ingress-nginx"
  chart = "nginx-ingress"
  repository = "https://helm.nginx.com/stable"
  namespace = "ingress-nginx"
  create_namespace = true
}


# L4 ingress
resource "helm_release" "haproxytech" {
  name = "ri-ingress-haproxy"
  chart = "kubernetes-ingress"
  repository = "https://haproxytech.github.io/helm-charts"
  namespace = "ingress-haproxy"
  create_namespace = true

  set {
    name = "controller.service.type"
    value = "LoadBalancer"
  }
}