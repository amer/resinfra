terraform {
  required_version = "=0.14.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.41.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.15.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  # More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # http://terraform.io/docs/providers/azurerm/index.html

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  #skip_provider_registration = true
}

provider "cloudflare" {
  email     = var.cloudflare_email
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "public-zone-ns" {
  name       = var.domain_name
  zone_id    = var.cloudflare_zone_id
  type       = "NS"
  ttl        = 1
  count      = 4
  value      = trimsuffix(element(azurerm_dns_zone.azure_zone.name_servers[*], count.index), ".")
  depends_on = [azurerm_dns_zone.azure_zone]
}

resource "cloudflare_record" "cluster_cname" {
  name    = "c${var.domain_name}"
  zone_id = var.cloudflare_zone_id
  type    = "CNAME"
  ttl     = 1
  value   = azurerm_kubernetes_cluster.main.fqdn
}

resource "azurerm_dns_zone" "azure_zone" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
}

//resource "azurerm_resource_provider_registration" "node-publicip-preview" {
//  name = "Microsoft.ContainerService"
//}

locals {
  aks_nsg_name     = data.external.aks_nsg_name.result.output
  aks_vmss_name    = data.external.aks_vmss_name.result.output
  public_node_ips  = split(",", data.external.public_node_ips.result.output)
}


resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.cidr_block]
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.cidr_block, 8, 1)]
}

resource "azurerm_subnet" "public" {
  name                 = "public"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.cidr_block, 8, 2)]
}

//resource "azurerm_route_table" "example" {
//  name                          = "${var.prefix}fwrt"
//  location                      = azurerm_resource_group.example.location
//  resource_group_name           = azurerm_resource_group.example.name
//  disable_bgp_route_propagation = false
//
//  route {
//    name           = "${var.prefix}fwrn"
//    address_prefix = "0.0.0.0/0"
//    next_hop_type  = "VirtualAppliance"
//    next_hop_in_ip_address = var.fwprivate_ip
//  }
//}

//resource "azurerm_subnet_route_table_association" "example" {
//  subnet_id      = azurerm_subnet.internal.id
//  route_table_id = azurerm_route_table.main.id
//}

resource "azurerm_network_security_rule" "allow-nodeports" {
  name                        = "any-nodeport"
  resource_group_name         = azurerm_kubernetes_cluster.main.node_resource_group
  network_security_group_name = local.aks_nsg_name
  priority                    = 400
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "30000-32767"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "allow-ICMP" {
  name                        = "any-ICMP"
  resource_group_name         = azurerm_kubernetes_cluster.main.node_resource_group
  network_security_group_name = local.aks_nsg_name
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "ICMP"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = "1.19.3"

  role_based_access_control {
    enabled = true
  }

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  default_node_pool {
    name                  = "internal"
    node_count            = var.agent_count
    vm_size               = var.vm_size
    type                  = "VirtualMachineScaleSets"
    availability_zones    = ["1", "2", "3"]
    enable_auto_scaling   = true
    min_count             = 2
    max_count             = 5
    os_disk_size_gb       = 30 # can't be smaller
    enable_node_public_ip = false
    vnet_subnet_id        = azurerm_subnet.internal.id

    tags = {
      Environment = "production"
      Zone        = "private"
    }
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
//    docker_bridge_cidr = "172.17.0.1/16"
//    service_cidr = cidrsubnet(var.cidr_block, 8, 1)
//    dns_service_ip = cidrhost(cidrsubnet(var.cidr_block, 8, 1), 10 )
    outbound_type     = "loadBalancer"
    load_balancer_sku = "standard"
    network_plugin    = "azure" # azure == CNI, use 'azure' if you want to install calico or cilium later
    # If you want to use Cilium, do NOT specify the '–network-policy' flag when creating
    # the cluster, as this will cause the Azure CNI plugin to push down unwanted iptables rules.
    #network_policy     = "calico"
  }

  //  identity {
  //    type = "SystemAssigned"
  //  }

  # TODO copy kube_config to ~/Download/somenamehere
  provisioner "local-exec" {
    command = <<EOF
      az aks get-credentials \
      --resource-group ${azurerm_kubernetes_cluster.main.resource_group_name} \
      --name ${azurerm_kubernetes_cluster.main.name} \
      --overwrite-existing
    EOF
    when    = create
  }

  # TODO use Helm chart instead of this ugly bash
  provisioner "local-exec" {
    command = "/bin/bash ${path.root}/scripts/install-kubernetes-dashboard.sh"
  }

  tags = {
    environment = "production"
    zone        = "private"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "public" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  name                  = "public"
  node_count            = 2
  vm_size               = "Standard_B2s"
  availability_zones    = ["1", "2", "3"]
  enable_auto_scaling   = true
  min_count             = 2
  max_count             = 5
  enable_node_public_ip = true
  vnet_subnet_id        = azurerm_subnet.public.id

  tags = {
    Environment = "production"
    Zone        = "public"
  }
}

//data "azurerm_virtual_machine_scale_set" "public-scale-set" {
//  name = "public-scale-set"
//  resource_group_name = azurerm_resource_group.main.name
//}


module "install_helm" {
  source                 = "../terraform-helm"
  host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
}

//module "ingress-nginx" {
//  source = "../app-ingress-nginx"
//  depends_on = [azurerm_kubernetes_cluster.main]
//}

//module "prometheus" {
//  source = "../app-prometheus"
//  depends_on = [azurerm_kubernetes_cluster.main]
//}

//module "cilium" {
//  source = "../app-cilium"
//  depends_on = [azurerm_kubernetes_cluster.main]
//
//  azure_client_id = var.client_id
//  azure_client_secret = var.client_secret
//  azure_node_resource_group = azurerm_kubernetes_cluster.main.node_resource_group
//  azure_subscription_id = var.subscription_id
//  azure_tenant_id = var.tenant_id
//  # To access hubble run the following command then open http://localhost:12000/
//  # kubectl port-forward -n kube-system svc/hubble-ui --address 0.0.0.0 --address :: 12000:80
//}

data "azurerm_kubernetes_cluster" "main" {
  name                = azurerm_kubernetes_cluster.main.name
  resource_group_name = azurerm_kubernetes_cluster.main.resource_group_name
}

data "external" "aks_nsg_name" {
  program = [
    "/bin/bash",
    "${path.root}/scripts/get_aks_nsg_name.sh",
    azurerm_kubernetes_cluster.main.node_resource_group
  ]
  depends_on = [azurerm_kubernetes_cluster_node_pool.public]
}

resource "null_resource" "info" {
  provisioner "local-exec" {
    command = <<EOF
          echo "
          -----------------------------------
          node_resource_group: ${azurerm_kubernetes_cluster.main.node_resource_group}
          -----------------------------------
          "
    EOF
  }
}

output "install_helm_cilium" {
  value = <<EOF
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.9.1 \
--namespace kube-system \
--set azure.enabled=true \
--set azure.resourceGroup="${azurerm_kubernetes_cluster.main.node_resource_group}" \
--set azure.subscriptionID="${var.subscription_id}" \
--set azure.tenantID="${var.tenant_id}" \
--set azure.clientID="${var.client_id}" \
--set azure.clientSecret="${var.client_secret}" \
--set tunnel=disabled \
--set ipam.mode=azure \
--set masquerade=false \
--set nodeinit.enabled=true \
--set hubble.listenAddress=":4244" \
--set hubble.relay.enabled=true \
--set hubble.ui.enabled=true
EOF
}

data "external" "aks_vmss_name" {
  program = [
    "/bin/bash",
    "${path.root}/scripts/get_virtual_machine_scale_set.sh",
    azurerm_kubernetes_cluster.main.node_resource_group
  ]
  depends_on = [azurerm_kubernetes_cluster.main]

}

data "external" "public_node_ips" {
  program = [
    "/bin/bash",
    "${path.root}/scripts/get_public_node_ips.sh",
    azurerm_kubernetes_cluster.main.node_resource_group,
    local.aks_vmss_name
  ]
  depends_on = [azurerm_kubernetes_cluster_node_pool.public]
}

data "azurerm_public_ip" "main" {
  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.main.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
}

resource "cloudflare_record" "public_nodes" {
  name       = "nodes.${cloudflare_record.cluster_cname.name}"
  zone_id    = var.cloudflare_zone_id
  type       = "A"
  ttl        = 1
  count      = azurerm_kubernetes_cluster_node_pool.public.node_count
  value      = element(local.public_node_ips[*], count.index)
  depends_on = [azurerm_kubernetes_cluster_node_pool.public, data.external.public_node_ips, ]
}
