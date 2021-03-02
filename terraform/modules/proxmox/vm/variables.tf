variable "path_public_key" {}
variable "path_private_key" {}

variable "proxmox_api_password" {}
variable "proxmox_api_user" {}
variable "proxmox_server_port" {}
variable "proxmox_server_address" {}
variable "proxmox_private_gateway_address" {}
variable "proxmox_vm_subnet_cidr" {}
variable "proxmox_public_ip_cidr" {}

variable "proxmox_target_node" {}
variable "vm_username" {}
variable "prefix" {}

variable "instances" {}

variable "shared_key" {}

variable "hetzner_gateway_ipv4_address" {}
variable "hetzner_vm_subnet_cidr" {}
variable "azure_gateway_ipv4_address" {}
variable "azure_vm_subnet_cidr" {}
variable "gcp_gateway_ipv4_address" {}    
variable "gcp_vm_subnet_cidr" {}

variable "num_cores" {}
variable "memory" {}