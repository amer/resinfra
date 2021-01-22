provider "hcloud" {
  token = var.hcloud_token
}

resource "random_id" "id" {
  byte_length = 4
}

// TODO: ensure this exists or intall on nake machine through preconf
data "hcloud_image" "cockroachdb-deploying-ready-snapshot" {
  with_selector = "cockroachdb_deployment"
}


# create the hosts file
resource "local_file" "hosts_file_creation" {
  depends_on = [
    hcloud_server_network.deployment-vm-into-subnet,
    var.hetzner_worker_hosts,
    var.azure_worker_hosts,
    var.gcp_worker_hosts,
    # pass the id of the strongswan ansible null_ressource to make sure that all other ansible scripts only run after
    # the strongswan ansible script has passed
    var.strongswan_ansible_updated
  ]

  content = templatefile("${path.module}/cockroach_host.ini.tpl", {
    cockroach_cluster_initializer = var.hetzner_worker_hosts[0]
    azure_hosts                   = var.azure_worker_hosts
    gcp_hosts                     = var.gcp_worker_hosts
    hetzner_hosts                 = var.hetzner_worker_hosts
    deployer_vm                   = hcloud_server_network.deployment-vm-into-subnet.ip
  })
  filename = "${path.module}/cockroach_host.ini"
}

/*
------------------------
    COCKROACHDB
------------------------
*/

data "template_file" "user_data" {
  template = file("${path.module}/preconf.yml")

  vars = {
    username   = "resinfra"
    public_key = file(var.path_public_key)
  }
}


// machine only for the deployment of cockroachdb
resource "hcloud_server" "cockroach_deployer" {
  name        = "${var.prefix}-hetzner-cockroach-deployer-${random_id.id.hex}"
  image       = data.hcloud_image.cockroachdb-deploying-ready-snapshot.id
  server_type = "cpx31"
  location    = var.location
  ssh_keys = [
  var.hcloud_ssh_key_id]
  user_data = data.template_file.user_data.rendered
}


# Put the deployment VM into the subnet
resource "hcloud_server_network" "deployment-vm-into-subnet" {
  server_id = hcloud_server.cockroach_deployer.id
  subnet_id = var.hetzner_subnet_id

}


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
    host        = hcloud_server.cockroach_deployer.ipv4_address
  }

  provisioner "file" {
    source      = "${path.module}/cockroach_host.ini"
    destination = "~/cockroach_host.ini"
  }
}

resource "null_resource" "cockroach_ansible" {
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
                --extra-vars 'priv_ip_list='${join(",", concat(var.azure_worker_hosts, var.gcp_worker_hosts, var.hetzner_worker_hosts))}''
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
  depends_on = [
    local_file.hosts_file_creation,
    hcloud_server.cockroach_deployer
  ]

  triggers = {
    instance_ids = join(",", concat([hcloud_server_network.deployment-vm-into-subnet.ip], var.azure_worker_hosts, var.gcp_worker_hosts, var.hetzner_worker_hosts))
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
                              monitoring_hosts='${join(",", concat([hcloud_server_network.deployment-vm-into-subnet.ip], var.azure_worker_hosts, var.gcp_worker_hosts, var.hetzner_worker_hosts))}''
      EOF
    ]
  }
}
