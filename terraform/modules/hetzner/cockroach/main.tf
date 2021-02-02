provider "hcloud" {
  token = var.hcloud_token
}

resource "random_id" "id" {
  byte_length = 4
}

// TODO: ensure this exists or intall on nake machine through preconf
// This is a preconfigured debian image with ansible, terraform and the git repository installed on it, as well as a key to fetch the git repo
data "hcloud_image" "cockroachdb-deploying-ready-snapshot" {
  with_selector = "cockroachdb_deployment"
}


# create the hosts file
# uses the prviate ip addresses of the deployed vms
resource "local_file" "hosts_file_creation" {
  depends_on = [
    hcloud_server_network.deployment-vm-into-subnet,
    var.hetzner_worker_hosts,
    var.azure_worker_hosts,
    var.gcp_worker_hosts,
    var.proxmox_worker_hosts,
    # pass the id of the strongswan ansible null_ressource to make sure that all other ansible scripts only run after
    # the strongswan ansible script has passed
    var.hcloud_strongswan_ansible_updated,
    var.proxmox_strongswan_ansible_updated
  ]

  content = templatefile("${path.module}/cockroach_host.ini.tpl", {
    cockroach_cluster_initializer = var.hetzner_worker_hosts[0]
    azure_hosts                   = var.azure_worker_hosts
    gcp_hosts                     = var.gcp_worker_hosts
    hetzner_hosts                 = var.hetzner_worker_hosts
    proxmox_hosts                 = var.proxmox_worker_hosts
    deployer_vm                   = var.hetzner_deployer_ip
  })
  filename = "${path.module}/cockroach_host.ini"
}

data "template_file" "user_data" {
  template = file("${path.module}/preconf.yml")

  vars = {
    username   = "resinfra"
    public_key = file(var.path_public_key)
  }
}

# Put the deployment VM into the subnet
resource "hcloud_server_network" "deployment-vm-into-subnet" {
  server_id = var.hetzner_deployer_id
  subnet_id = var.hetzner_subnet_id
  ip = var.hetzer_deployer_internal_ip
}


/*
------------------------
    COCKROACHDB
------------------------
*/

resource "null_resource" "cockroach_ansible" {
  depends_on = [
    local_file.hosts_file_creation,
    null_resource.nodeexporter_ansible,
    null_resource.monitoring_ansible
  ]

  triggers = {
    local_file_id = local_file.hosts_file_creation.id
  }

  connection {
    type        = "ssh"
    user        = "resinfra"
    private_key = file(var.path_private_key)
    host        = hcloud_server.cockroach_deployer.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH is now ready!'",
      "echo '${file(var.path_private_key)}' >> ~/.ssh/vm_key",
      "chmod 0600 ~/.ssh/vm_key",
      "cd ~/resinfra/",
      "git pull",
      "git checkout ${var.git_checkout_branch}",
      "git pull",
      "cd ansible",
      <<EOF
        ansible-playbook cockroach_playbook.yml \
                -i /home/resinfra/cockroach_host.ini \
                --ssh-common-args='-o StrictHostKeyChecking=no' \
                --private-key ~/.ssh/vm_key \
                --extra-vars 'priv_ip_list='${join(",", concat(var.azure_worker_hosts, var.gcp_worker_hosts, var.hetzner_worker_hosts, var.proxmox_worker_hosts))}''
      EOF
    ]
  }
}

/*
------------------
    CONSUL
------------------
*/
resource "null_resource" "consul_ansible" {
  depends_on = [
    local_file.hosts_file_creation,
  ]

  triggers = {
    local_file_id = local_file.hosts_file_creation.id
  }

  connection {
    type        = "ssh"
    user        = "resinfra"
    private_key = file(var.path_private_key)
    host        = hcloud_server.cockroach_deployer.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "cd ~/resinfra/",
      "git pull",
      "git checkout ${var.git_checkout_branch}",
      "git pull",
      "cd ansible",
      <<EOF
        ansible-playbook consul_playbook.yml \
                -i /home/resinfra/cockroach_host.ini \
                -l deployer_server \
                --ssh-common-args='-o StrictHostKeyChecking=no' \
                --private-key ~/.ssh/vm_key \
                --extra-vars 'server='true''
      EOF
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "cd ~/resinfra/",
      "git pull",
      "git checkout ${var.git_checkout_branch}",
      "git pull",
      "cd ansible",
      <<EOF
        ansible-playbook consul_playbook.yml \
                -i /home/resinfra/cockroach_host.ini \
                -l cockroach_main_servers \
                --ssh-common-args='-o StrictHostKeyChecking=no' \
                --private-key ~/.ssh/vm_key \
                --extra-vars "server=false leader_node=${hcloud_server_network.deployment-vm-into-subnet.ip}"
      EOF
    ]
  }
}

/*
------------------
    MONITORING
------------------
*/


resource "null_resource" "nodeexporter_ansible" {
  depends_on = [
    local_file.hosts_file_creation
  ]

  triggers = {
    local_file_id = local_file.hosts_file_creation.id
  }

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
      "git checkout ${var.git_checkout_branch}",
      "git pull",
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
  depends_on = [
    local_file.hosts_file_creation,
    hcloud_server.cockroach_deployer,
    null_resource.nodeexporter_ansible
  ]

  triggers = {
    instance_ids = join(",", concat([hcloud_server_network.deployment-vm-into-subnet.ip], var.azure_worker_hosts, var.gcp_worker_hosts, var.hetzner_worker_hosts, var.proxmox_worker_hosts))
  }

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
      "git checkout ${var.git_checkout_branch}",
      "git pull",
      "cd ansible",
      "mkdir -p /home/resinfra/grafana/provisioning/datasources",
      <<EOF
        ansible-playbook monitoring_playbook.yml \
                -i ${hcloud_server_network.deployment-vm-into-subnet.ip}, \
                -u 'resinfra' \
                --ssh-common-args='-o StrictHostKeyChecking=no' \
                --private-key ~/.ssh/vm_key \
                --extra-vars 'prometheus_host='localhost' \
                              monitoring_hosts='${join(",", concat([hcloud_server_network.deployment-vm-into-subnet.ip], var.azure_worker_hosts, var.gcp_worker_hosts, var.hetzner_worker_hosts, var.proxmox_worker_hosts))}''
      EOF
    ]
  }
}
