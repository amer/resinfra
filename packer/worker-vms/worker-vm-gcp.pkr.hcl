variable "gcp_project_id" {}
variable "gcp_region" {}
variable "gcp_service_account_path" {}

variable "consul_leader_node" {}
variable "resinfra_vpc_cidr" {}

variable "path_pub_key" {}

source "googlecompute" "gcp" {
  account_file = var.gcp_service_account_path
  project_id = var.gcp_project_id
  source_image_family = "debian-10"
  source_image = "debian-10-buster-v20210122"
  ssh_username = "root"
  image_name = "gcp-worker-vm"
  zone = var.gcp_region
  image_labels = {
    gcp-worker-vm = ""
  }
}

build {
  sources = [
    "source.googlecompute.gcp"
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
    - pub_key_path: path to public key that will be added to resinfra user
    - leader_node: private ip of the consul leader node. Consul agents will use that ip to register themselves to the
          consul cluster.
    - ansible_python_interpreter: on debian10, python2 is still the default python.
  */
  provisioner "ansible" {
    playbook_file = "../ansible/worker_vm_playbook.yml"
    extra_arguments = [
      "--extra-vars",
      "resinfra_vpc_cidr=${var.resinfra_vpc_cidr} pub_key_path=${var.path_pub_key} leader_node=${var.consul_leader_node} ansible_python_interpreter=/usr/bin/python3"]
  }
}
