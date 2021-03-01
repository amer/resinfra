# Hetzner
variable "hcloud_token" {}

variable "enable_floating_ip" {
  type    = bool
  default = false
}

variable "enable_volume" {
  type    = bool
  default = false
}

variable "volume_size" {
  default = 100
}

variable "location" {
  default = "nbg1"
}

variable "server_type" {
  default     = "cx31"
  description = "server type to get. Refer to https://www.hetzner.com/cloud for more information about server types."
  # cx11: 1vCPU, 2GM RAM, 20GB Disc
}

variable "prefix" {}

variable "instances" {}

variable "hetzner_vm_subnet_cidr" {}
variable "hetzner_vpc_cidr" {}
variable "azure_vm_subnet_cidr" {}
variable "gcp_vm_subnet_cidr" {}
variable "proxmox_vm_subnet_cidr" {}

variable "azure_gateway_ipv4_address" {}
variable "gcp_gateway_ipv4_address" {}
variable "proxmox_gateway_ipv4_address" {}

variable "shared_key" {}

variable "path_private_key" {}
variable "path_public_key" {}

variable "consul_leader_ip" {}

variable "machine_type" {}