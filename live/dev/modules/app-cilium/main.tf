resource "helm_release" "cilium-stable" {
  name = "my-cilium"
  chart = "cilium"
  repository = "https://helm.cilium.io/"
  namespace = "kube-system"
  version = "1.9.1"

  set {
    name = "azure.enabled"
    value = "true"
  }

  set {
    name = "azure.resourceGroup"
    value = var.azure_node_resource_group
  }

  set {
    name = "azure.subscriptionID"
    value = var.azure_subscription_id
  }

  set {
    name = "azure.tenantID"
    value = var.azure_tenant_id
  }

  set {
    name = "azure.clientID"
    value = var.azure_client_id
  }

  set {
    name = "clientSecret"
    value = var.azure_client_secret
  }

  set {
    name = "tunnel"
    value = "disabled"
  }

  set {
    name = "ipam.mode"
    value = "azure"
  }

  set {
    name = "masquerade"
    value = "false"
  }

  set {
    name = "nodeinit.enabled"
    value = "true"
  }

  set {
    name = "hubble.listenAddress"
    value = ":4244"
  }

  set {
    name = "hubble.relay.enabled"
    value = "true"
  }

  set {
    name = "hubble.ui.enabled"
    value = "true"
  }
}



