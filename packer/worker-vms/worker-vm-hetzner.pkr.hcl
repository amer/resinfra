variable "hcloud_token" {}
variable "consul_leader_node" {}
variable "resinfra_vpc_cidr" {}

variable "path_pub_key" {}

source "hcloud" "hcloud" {
  token = var.hcloud_token
  image = "debian-10"
  location = "nbg1"
  server_type = "cx11"
  ssh_username = "root"
  snapshot_name = "worker-vm"
  server_name = "hetzner-worker-vm"
  snapshot_labels = {
    hetzner-worker-vm = ""
  }
}

build {
  sources = [
    "source.hcloud.hcloud"
  ]

  # install some utilities
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y software-properties-common git vim gnupg2"]
  }

  /*
  install worker VM tooling. For further information about the single components, refer to the ansible playbook file.
  extra vars reference:
    - resinfra_vpc_cidr: the overall cidr of the resinfra net.
          Required to setup consul workers to use the correct network interface.
    - server: flag passed to the consul playbook to start consul in agent mode
    - pub_key_path: path to public key that will be added to resinfra user
    - leader_node: private ip of the consul leader node. Consul agents will use that ip to register themselves to the
          consul cluster.
    - ansible_python_interpreter: on debian10, python2 is still the default python.
  */
  provisioner "ansible" {
    playbook_file = "../ansible/worker_vm_playbook.yml"
    extra_arguments = [
      "--extra-vars",
      "resinfra_vpc_cidr=${var.resinfra_vpc_cidr} server=false pub_key_path=${var.path_pub_key} leader_node=${var.consul_leader_node} ansible_python_interpreter=/usr/bin/python3"]
  }
}