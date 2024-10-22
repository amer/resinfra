variable "proxmox_url" {}
variable "proxmox_user" {}
variable "proxmox_pw" {}
variable "consul_leader_node" {}
variable "resinfra_vpc_cidr" {}

variable "path_pub_key" {}

source "proxmox-clone" "proxmox" {
  proxmox_url = var.proxmox_url
  username = var.proxmox_user
  password = var.proxmox_pw
  node = "host1"
  clone_vm = "debian-cloudinit-10G"
  ssh_username = "root"
  insecure_skip_tls_verify = "true"
  cores = 2
  sockets = "1"
  cpu_type = "host"
  memory = 2048
  os = "cloud-init"
  template_name = "proxmox-worker-vm"
}

build {
  sources = [
    "source.proxmox-clone.proxmox"
  ]

  # install some utilities
   provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y software-properties-common git vim gnupg2"]
  }

  /*
  install gateway VM tooling. For further information about the single components, refer to the ansible playbook file.
  extra vars reference:
    - resinfra_vpc_cidr: the overall cidr of the resinfra net.
          Required to setup consul workers to use the correct network interface.
    - pub_key_path: path to public key that will be added to resinfra user
    - leader_node: private ip of the consul leader node. Consul agents will use that ip to register themselves to the
          consul cluster.
    - ansible_python_interpreter: on debian10, python2 is still the default python.
  */
  provisioner "ansible" {
    playbook_file = "../ansible/libreswan_gateway_playbook.yml"
    extra_arguments = [
      "--extra-vars",
      "resinfra_vpc_cidr=${var.resinfra_vpc_cidr} pub_key_path=${var.path_pub_key} leader_node=${var.consul_leader_node} ansible_python_interpreter=/usr/bin/python3"]
  }
}
