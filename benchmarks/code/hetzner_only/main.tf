provider "hcloud" {
  token = var.hcloud_token
}

resource "random_id" "id" {
  byte_length = 4
}


resource "hcloud_ssh_key" "default" {
  name = "${var.prefix}-hetzner-key-${random_id.id.hex}"
  public_key = file(var.path_public_key)
}

data "hcloud_image" "deployer-snapshot" {
  with_selector = "hetzner-benchmark"
  most_recent = true
}


data "hcloud_image" "worker-image" {
  with_selector = "hetzner-worker-vm"
  most_recent = true
}


# Create a virtual network
resource "hcloud_network" "main" {
  name     = "${var.prefix}-network-${random_id.id.hex}"
  ip_range = "10.0.0.0/8"
}

# Create a subnet for both the gateway and the vms
resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.3.0.0/24"
}

resource "hcloud_server" "benchmarking-vm" {
  name = "${var.prefix}-hetzner-benchmarker-${random_id.id.hex}"
  image = data.hcloud_image.deployer-snapshot.id
  server_type = var.server_type
  ssh_keys = [
    hcloud_ssh_key.default.id]
  location = var.location

}

resource "hcloud_server_network" "deployer-vm" {
  server_id = hcloud_server.benchmarking-vm.id
  subnet_id = hcloud_network_subnet.main.id
  ip ="10.3.0.254"
}

resource "hcloud_server" "worker-vm" {
  count = var.num_vms
  name = "${var.prefix}-hetzner-vm-${count.index + 1}-${random_id.id.hex}"
  image = data.hcloud_image.worker-image.id
  server_type = var.server_type
  location = var.location
  ssh_keys = [
    hcloud_ssh_key.default.id]
}

# Put the VMs into the subnet
resource "hcloud_server_network" "worker-vms-into-subnet" {
  count = var.num_vms
  server_id = hcloud_server.worker-vm[count.index].id
  subnet_id = hcloud_network_subnet.main.id
}

resource "local_file" "hosts_file_creation" {

  content = templatefile("cockroach_host.ini.tpl", {
    cockroach_cluster_initializer = hcloud_server_network.worker-vms-into-subnet[0].ip
    hetzner_hosts = hcloud_server_network.worker-vms-into-subnet.*.ip
  })
  filename = "cockroach_host.ini"
}
# copy over the hosts file to the deployer vm
resource "null_resource" "hosts_file_copy" {
  depends_on = [
    local_file.hosts_file_creation
  ]

  triggers = {
    local_file_id = local_file.hosts_file_creation.id
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.path_private_key)
    host        = hcloud_server.benchmarking-vm.ipv4_address
  }

  provisioner "file" {
    source      = "cockroach_host.ini"
    destination = "~/cockroach_host.ini"
  }
}

resource "null_resource" "cockroach_ansible" {
  depends_on = [
    local_file.hosts_file_creation,
    null_resource.hosts_file_copy
  ]

  triggers = {
    local_file_id = local_file.hosts_file_creation.id
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.path_private_key)
    host        = hcloud_server.benchmarking-vm.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH is now ready!'",
      "sleep 30",
      "echo '${file(var.path_private_key)}' >> ~/.ssh/vm_key",
      "chmod 0600 ~/.ssh/vm_key",
      "cd /resinfra",
      # "git pull",
      "git checkout benchmarking",
      "cd ansible",
      <<EOF
        ansible-playbook cockroach_playbook.yml \
                -i ~/cockroach_host.ini \
                -u root \
                --ssh-common-args='-o StrictHostKeyChecking=no' \
                --private-key ~/.ssh/vm_key \
                --extra-vars 'priv_ip_list='${join(",", hcloud_server_network.worker-vms-into-subnet.*.ip)}' ansible_python_interpreter=/usr/bin/python3'
      EOF
    ]
  }
}


output "hcloud_private_ip_addresses"{
  value = hcloud_server_network.worker-vms-into-subnet.*.ip
}
