variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {}
variable "consul_leader_node" {}
variable "resinfra_vpc_cidr" {}
variable "path_pub_key" {}
variable "azure_resource_group" {}

source "azure-arm" "azure" {
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id

  os_type = "linux"
  vm_size = "Standard_D2s_v3"
  image_publisher = "Debian"
  image_offer = "debian-10"
  image_sku = "10"

  build_resource_group_name = var.azure_resource_group

  managed_image_resource_group_name = var.azure_resource_group
  managed_image_name = "azure-worker-vm"
}

build {
  sources = [
    "source.azure-arm.azure"
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
