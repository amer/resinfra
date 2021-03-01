variable "hcloud_token" {}
variable "path_private_key" {}
variable "path_pub_key" {}
variable "resinfra_vpc_cidr" {}

source "hcloud" "hcloud" {
  token = var.hcloud_token
  image = "ubuntu-20.04"
  location = "nbg1"
  server_type = "cx11"
  ssh_username = "root"
  snapshot_name = "resinfra-vm"
  server_name = "hetzner-resinfra-vm"
  snapshot_labels = {
    hetzner-benchmark = ""
  }
}

build {
  sources = [
    "source.hcloud.hcloud"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y ansible git vim software-properties-common",
      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt-get update && sudo apt-get install -y terraform"
    ]

  }
  provisioner "ansible" {
    playbook_file = "../ansible/deployer_vm_playbook.yml"
    extra_arguments = [
      "--extra-vars",
      "server='true' resinfra_vpc_cidr=${var.resinfra_vpc_cidr} priv_key_path=${var.path_private_key} pub_key_path=${var.path_pub_key} ansible_python_interpreter=/usr/bin/python3"]
  }
}