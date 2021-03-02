variable "hcloud_token" {}
variable "path_private_key" {}
variable "path_pub_key" {}
variable "resinfra_vpc_cidr" {}

source "hcloud" "hcloud" {
  token = var.hcloud_token
  image = "debian-10"
  location = "nbg1"
  server_type = "cx11"
  ssh_username = "root"
  snapshot_name = "resinfra-vm"
  server_name = "hetzner-resinfra-vm"
  snapshot_labels = {
    hetzner-deployer = ""
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
      "sudo apt-get install -y ansible software-properties-common git vim",
      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt-get update && sudo apt-get install -y terraform"
    ]

  /*
  install resinfra VM tooling. For further information about the single components, refer to the ansible playbook file.
  extra vars reference:
    - pub_key_path: path to public key that will be added to resinfra user
    - priv_key_path: path to private key (matching public key above!) that will be used to connect to the single worker
          vms.
    - ansible_python_interpreter: on debian10, python2 is still the default python.
  */
  }
  provisioner "ansible" {
    playbook_file = "../ansible/deployer_vm_playbook.yml"
    extra_arguments = [
      "--extra-vars",
      "resinfra_vpc_cidr=${var.resinfra_vpc_cidr} priv_key_path=${var.path_private_key} pub_key_path=${var.path_pub_key} ansible_python_interpreter=/usr/bin/python3"]
  }
}