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
variable "proxmox_worker_hosts" {}

variable "hcloud_ssh_key_id" {}

variable "hcloud_strongswan_ansible_updated" {}
variable "proxmox_strongswan_ansible_updated" {}


variable "hetzer_deployer_internal_ip" {}
variable "hetzner_deployer_id" {}
variable "hetzner_deployer_ip" {}
