resource "helm_release" "nginx-stable" {
  name = "ri-ingress-nginx"
  chart = "nginx-ingress"
  repository = "https://helm.nginx.com/stable"
  namespace = "ingress-nginx"
  create_namespace = true

  set {
    name = "controller.publishService.enabled"
    value = true
  }

  set {
    name = "controller.replicaCount"
    value = "2"
  }

  set {
    name = "prometheus.create"
    value = true
  }

  set {
    name = "enableLatencyMetrics"
    value = true
  }

  set {
    name = "controller.publishService.enabled"
    value = true
  }
}