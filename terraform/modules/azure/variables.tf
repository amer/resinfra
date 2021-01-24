variable "client_id" {}
variable "client_secret" {}
variable "subscription_id" {}
variable "tenant_id" {}
variable "location" {}
variable "vm_size" {}
variable "instances" {}

variable "prefix" {}

variable "hcloud_gateway_ipv4_address" {}
variable "gcp_gateway_ipv4_address" {}
variable "proxmox_gateway_ipv4_address" {}

variable "hcloud_vm_subnet_cidr" {}
variable "azure_vm_subnet_cidr" {}
variable "gcp_vm_subnet_cidr" {}
variable "proxmox_vm_subnet_cidr" {}


variable "azure_vpc_cidr" {}
variable "azure_gateway_subnet_cidr" {}

variable "shared_key" {}

variable "path_private_key" {}
variable "path_public_key" {}

