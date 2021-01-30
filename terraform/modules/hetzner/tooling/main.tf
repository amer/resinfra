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

  content = templatefile("${path.module}/hosts.ini.tpl", {
    cockroach_cluster_initializer = var.hetzner_worker_hosts[0]
    azure_hosts                   = var.azure_worker_hosts
    gcp_hosts                     = var.gcp_worker_hosts
    hetzner_hosts                 = var.hetzner_worker_hosts
    proxmox_hosts                 = var.proxmox_worker_hosts
    deployer_vm                   = hcloud_server_network.deployment-vm-into-subnet.ip
  })
  filename = "${path.module}/hosts.ini"
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
    user        = "resinfra"
    private_key = file(var.path_private_key)
    host        = var.hetzer_deployer_external_ip
  }

  provisioner "file" {
    source      = "${path.module}/hosts.ini"
    destination = "~/hosts.ini"
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
    host        = var.hetzer_deployer_external_ip
  }


  provisioner "remote-exec" {
    inline = [
      "cd /resinfra",
      "git pull",
      "git checkout ${var.git_checkout_branch}",
      "git pull",
      "cd ansible",
      <<EOF
        ansible-playbook consul_playbook.yml \
                -i ~/hosts.ini \
                -l main_servers \
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
    host        = var.hetzer_deployer_external_ip
  }


  provisioner "remote-exec" {
    inline = [
      "cd /resinfra/",
      "git pull",
      "git checkout ${var.git_checkout_branch}",
      "git pull",
      "cd ansible",
      <<EOF
        ansible-playbook nodeexporter_playbook.yml \
                -i ~/hosts.ini \
                --ssh-common-args='-o StrictHostKeyChecking=no' \
                --private-key ~/.ssh/vm_key \
      EOF
    ]
  }
}

