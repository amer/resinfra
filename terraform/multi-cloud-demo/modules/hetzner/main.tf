terraform {
  required_version = ">=0.13.5"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.23.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name       = "${var.prefix}-hetzner-key-${random_id.id.hex}"
  public_key = file(var.path_public_key)
}

// get snapshot with ansible installed for cockroachdb deployment
data "hcloud_image" "cockroachdb-deploying-ready-snapshot" {
  with_selector = "cockroachdb_deployment"
}

data "hcloud_image" "latest-debian" {
  name        = "debian-10"
  most_recent = "true"
}

data "template_file" "user_data" {
  template = file("${path.module}/preconf.yml")

  vars = {
    username   = "resinfra"
    public_key = file(var.path_public_key)
  }
}

resource "hcloud_server" "main" {
  count       = var.instances
  name        = "${var.prefix}-hetzner-vm-${count.index + 1}-${random_id.id.hex}"
  image       = data.hcloud_image.latest-debian.name
  server_type = var.server_type
  location    = var.location
  ssh_keys = [
  hcloud_ssh_key.default.id]
  user_data = data.template_file.user_data.rendered
}

// machine only for the deployment of cockroachdb
resource "hcloud_server" "cockroach_deployer" {
  name        = "${var.prefix}-hetzner-cockroach-deployer-${random_id.id.hex}"
  image       = data.hcloud_image.cockroachdb-deploying-ready-snapshot.id
  server_type = "cpx31"
  location    = var.location
  ssh_keys = [
  hcloud_ssh_key.default.id]
  user_data = data.template_file.user_data.rendered
}

resource "hcloud_floating_ip" "main" {
  count         = var.enable_floating_ip ? var.instances : 0
  name          = "${var.prefix}-floating_ip-${count.index + 1}-${random_id.id.hex}"
  type          = "ipv4"
  home_location = var.location
  server_id     = hcloud_server.main.*.id[count.index]
}

resource "hcloud_volume" "main" {
  count     = var.enable_volume ? var.instances : 0
  name      = "${var.prefix}-volume-${count.index + 1}-${random_id.id.hex}"
  size      = var.volume_size
  server_id = hcloud_server.main.*.id[count.index]
  automount = "true"
  format    = "xfs"
}


resource "random_id" "id" {
  byte_length = 4
}

# Put that VM into the subnet
resource "hcloud_server_network" "normal-vms-into-subnet" {
  count     = var.instances
  server_id = hcloud_server.main[count.index].id
  subnet_id = hcloud_network_subnet.main.id
}


# Put the deployment VM into the subnet
resource "hcloud_server_network" "deployment-vm-into-subnet" {
  server_id = hcloud_server.cockroach_deployer.id
  subnet_id = hcloud_network_subnet.main.id

}

# create the hosts file for the cockroach deployment
resource "local_file" "hosts_file_creation" {
  depends_on = [
    hcloud_server_network.normal-vms-into-subnet,
    hcloud_server_network.deployment-vm-into-subnet,
    hcloud_server_network.internal
  ]
  content = templatefile("${path.module}/cockroach_host.ini.tpl", {
    cockroach_cluster_initializer = hcloud_server_network.deployment-vm-into-subnet.ip,
    azure_hosts                   = var.azure_worker_hosts
    gcp_hosts                     = var.gcp_worker_hosts
    hetzner_hosts                 = hcloud_server_network.normal-vms-into-subnet.*.ip
    deployer_vm                   = hcloud_server_network.deployment-vm-into-subnet.ip
  })
  filename = "${path.module}/cockroach_host.ini"
}

resource "null_resource" "hosts_file_copy" {
  depends_on = [
  local_file.hosts_file_creation]
  connection {
    type        = "ssh"
    user        = "resinfra"
    private_key = file(var.path_private_key)
    host        = hcloud_server.cockroach_deployer.ipv4_address
  }

  provisioner "file" {
    source      = "${path.module}/cockroach_host.ini"
    destination = "~/cockroach_host.ini"
  }
}
/*
resource "null_resource" "cockroach_ansible" {
  depends_on = [
  null_resource.hosts_file_copy,
  null_resource.strongswan_ansible]

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH is now ready!'",
      "echo '${file(var.path_private_key)}' >> ~/.ssh/vm_key",
      "chmod 0600 ~/.ssh/vm_key",
      "cd ~/resinfra/",
      "git pull",
      "git checkout multi-cloud",
      "cd ansible",
      <<EOF
        ansible-playbook cockroach_playbook.yml \
                -i /home/resinfra/cockroach_host.ini \
                --ssh-common-args='-o StrictHostKeyChecking=no' \
                --private-key ~/.ssh/vm_key \
                --extra-vars 'priv_ip_list='${join(",", concat(var.azure_worker_hosts, var.gcp_worker_hosts, hcloud_server_network.normal-vms-into-subnet.*.ip))}''
      EOF
    ]
  }

  connection {
    type        = "ssh"
    user        = "resinfra"
    private_key = file(var.path_private_key)
    host        = hcloud_server.cockroach_deployer.ipv4_address
  }
}
*/

### HETZNER ###
# Create a virtual network
resource "hcloud_network" "main" {
  name     = "${var.prefix}-network"
  ip_range = var.hetzner_vpc_cidr
}

# Create a subnet for both the gateway and the vms
resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.hetzner_vm_subnet_cidr
}

### MANUAL GATEWAY VM(S) ###

# Create VM that will be the gateway
resource "hcloud_server" "gateway" {
  name        = "${var.prefix}-hetzner-gateway-vm"
  image       = "ubuntu-20.04"
  server_type = "cx11"
  location    = "nbg1"
  ssh_keys = [
  hcloud_ssh_key.default.id]
}

# Put the Gateway VM into the subnet and run ansible to configure it
resource "hcloud_server_network" "internal" {
  server_id = hcloud_server.gateway.id
  subnet_id = hcloud_network_subnet.main.id
}

resource "null_resource" "strongswan_ansible" {
  provisioner "remote-exec" {
    inline = [
    "echo 'SSH is now ready!'"]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.path_private_key)
      host        = hcloud_server.gateway.ipv4_address
    }
  }

  provisioner "local-exec" {
    command = <<EOF
        ansible-playbook -i '${hcloud_server.gateway.ipv4_address},'  \
            -u 'root' ${path.module}/../../../../ansible/strongswan_playbook.yml \
            --ssh-common-args='-o StrictHostKeyChecking=no' \
            --extra-vars 'public_gateway_ip='${hcloud_server.gateway.ipv4_address}' \
                          local_cidr='${var.hetzner_vpc_cidr}' \
                          azure_remote_gateway_ip='${var.azure_gateway_ipv4_address}' \
                          azure_remote_cidr='${var.azure_vm_subnet_cidr}'
                          gcp_remote_gateway_ip='${var.gcp_gateway_ipv4_address}' \
                          gcp_remote_cidr='${var.gcp_vm_subnet_cidr}' \
                          psk='${var.shared_key}'' \
            --key-file '${var.path_private_key}'
  EOF
  }
}

# create a route in the Hetzner Network for Azure traffic
resource "hcloud_network_route" "azure_via_gateway" {
  network_id  = hcloud_network.main.id
  destination = var.azure_vm_subnet_cidr
  gateway     = hcloud_server_network.internal.ip
}

# create a route in the Hetzner Network for GCP traffic
resource "hcloud_network_route" "gcp_via_gateway" {
  network_id  = hcloud_network.main.id
  destination = var.gcp_vm_subnet_cidr
  gateway     = hcloud_server_network.internal.ip
}

/*
------------------
    MONITORING
------------------
*/

/*
resource "null_resource" "nodeexporter_ansible" {
  depends_on = [null_resource.hosts_file_copy]

  connection {
    type        = "ssh"
    user        = "resinfra"
    private_key = file(var.path_private_key)
    host        = hcloud_server.cockroach_deployer.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${file(var.path_private_key)}' >> ~/.ssh/vm_key",
      "chmod 0600 ~/.ssh/vm_key",
      "cd ~/resinfra/",
      "git pull",
      "git checkout multi-cloud",
      "cd ansible",
      <<EOF
        ansible-playbook nodeexporter_playbook.yml \
                -i /home/resinfra/cockroach_host.ini \
                --ssh-common-args='-o StrictHostKeyChecking=no' \
                --private-key ~/.ssh/vm_key \
      EOF
    ]
  }
}


resource "null_resource" "monitoring_ansible" {
// Depends_on does not support null_resources
  depends_on = [null_resource.nodeexporter_ansible]
  provisioner "remote-exec" {
    inline = [
      "echo '${file(var.path_private_key)}' >> ~/.ssh/vm_key",
      "chmod 0600 ~/.ssh/vm_key",
      "cd ~/resinfra/",
      "git pull",
      "git checkout multi-cloud",
      "cd ansible",
      "mkdir -p /home/resinfra/grafana/provisioning/datasources",
      <<EOF
        ansible-playbook monitoring_playbook.yml \
                -i ${hcloud_server_network.deployment-vm-into-subnet.ip}, \
                -u 'resinfra' \
                --ssh-common-args='-o StrictHostKeyChecking=no' \
                --private-key ~/.ssh/vm_key \
                --extra-vars 'prometheus_host='localhost' \
                              monitoring_hosts='${join(",", concat([hcloud_server_network.deployment-vm-into-subnet.ip], var.azure_worker_hosts, var.gcp_worker_hosts, hcloud_server_network.normal-vms-into-subnet.*.ip))}''
      EOF
    ]
  }

  connection {
    type        = "ssh"
    user        = "resinfra"
    private_key = file(var.path_private_key)
    host        = hcloud_server.cockroach_deployer.ipv4_address
  }
}
*/

resource "null_resource" "ansible_run_all" {
  depends_on = [null_resource.hosts_file_copy]
  provisioner "remote-exec" {
    inline = [
      "echo '${file(var.path_private_key)}' >> ~/.ssh/vm_key",
      "chmod 0600 ~/.ssh/vm_key",
      "cd ~/resinfra/",
      "git pull",
      "git checkout multi-cloud",
      "cd ansible",
      "mkdir -p /home/resinfra/grafana/provisioning/datasources",
      "ansible-playbook monitoring_playbook.yml -i ${hcloud_server_network.deployment-vm-into-subnet.ip}, -u 'resinfra' --ssh-common-args='-o StrictHostKeyChecking=no' --private-key ~/.ssh/vm_key --extra-vars 'prometheus_host='localhost' monitoring_hosts='${join(",", concat([hcloud_server_network.deployment-vm-into-subnet.ip], var.azure_worker_hosts, var.gcp_worker_hosts, hcloud_server_network.normal-vms-into-subnet.*.ip))}''",
      "ansible-playbook nodeexporter_playbook.yml -i /home/resinfra/cockroach_host.ini --ssh-common-args='-o StrictHostKeyChecking=no' --private-key ~/.ssh/vm_key",
      "ansible-playbook cockroach_playbook.yml -i /home/resinfra/cockroach_host.ini --ssh-common-args='-o StrictHostKeyChecking=no' --private-key ~/.ssh/vm_key --extra-vars 'priv_ip_list='${join(",", concat(var.azure_worker_hosts, var.gcp_worker_hosts, hcloud_server_network.normal-vms-into-subnet.*.ip))}''"
    ]

  }

  connection {
    type        = "ssh"
    user        = "resinfra"
    private_key = file(var.path_private_key)
    host        = hcloud_server.cockroach_deployer.ipv4_address
  }
}