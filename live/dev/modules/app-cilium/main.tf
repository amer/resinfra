resource "helm_release" "cilium-stable" {
  name = "my-cilium"
  chart = "cilium"
  repository = "https://helm.cilium.io/"
  namespace = "kube-system"
  version = "1.9.1"

  set {
    name = "nodeinit.enabled"
    value = true
  }

  set {
    name = "kubeProxyReplacement"
    value = "partial"
  }

  set {
    name = "hostServices.enabled"
    value = false
  }

  set {
    name = "externalIPs.enabled"
    value = false
  }

  set {
    name = "nodePort.enabled"
    value = false
  }

  set {
    name = "hostPort.enabled"
    value = false
  }

  set {
    name = "bpf.masquerade"
    value = false
  }

  set {
    name = "image.pullPolicy"
    value = "IfNotPresent"
  }

  set {
    name = "ipam.mode"
    value = "kubernetes"
  }
}