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

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y software-properties-common git vim gnupg2"]
  }

  provisioner "ansible" {
    playbook_file = "../ansible/worker_vm_playbook.yml"
    extra_arguments = [
      "--extra-vars",
      "resinfra_vpc_cidr=${var.resinfra_vpc_cidr} server=false pub_key_path=${var.path_pub_key} leader_node=${var.consul_leader_node} ansible_python_interpreter=/usr/bin/python3"]
  }
}