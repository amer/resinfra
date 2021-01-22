variable "prefix" {}
variable "hcloud_token" {}
variable "path_private_key" {}
variable "path_public_key" {}

variable "location" {
  default = "nbg1"
}

variable "hetzner_subnet_id" {}
variable "azure_worker_hosts" {}
variable "gcp_worker_hosts" {}
variable "hetzner_worker_hosts" {}

variable "hcloud_ssh_key_id" {}

variable "strongswan_ansible_updated" {}