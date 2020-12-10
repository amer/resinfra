# General - these will be used among cloud providers
variable "public_key_path" {
  description = "path to public key that will be uploaded to aws"
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "path to private key, used to access instance"
  default     = "~/.ssh/id_rsa"
}

variable "username" {
  description = "username to be used among ALL providers. Don't choose admin or root."
}

variable "prefix" {
  default = "resinfra-mc"
}

variable "instances" {
  default = "1"
}

# Cloud provider specific variables

# Azure
variable resinfra_subscription_id {}

variable "resinfra_vm_size" {
	description = "Size of VM. Default: Standard_DS1_v2 # Specs of Standard_DS1_v2 vm: (vCPU: 1, Memory: 3.5 GiB, Storage (SSD): 7 GiB)"
	default = "Standard_DS1_v2"
}

# AWS
variable aws_access_key {}
variable aws_secret_key {}

variable "region" {
  type        = string
  description = "AWS region for resources to be created"
  default     = "eu-central-1"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the instance to be created"
  default     = "t2.micro" # 1 vCPU 1gb ram
}

variable "remote_user" {
  description = "user for ssh connection"
  default     = "ubuntu"
}

# Hetzner
variable "hcloud_token" {}

variable "enable_floating_ip" {
  type        = bool
  default     = false
}

variable "enable_volume" {
  type        = bool
  default     = false
}

variable "volume_size"{
    default = 100
}

variable "location" {
  default = "nbg1"
}

variable "instances" {
  default = "1"
}

variable "server_type" {
  default = "cx11"
  description = "server type to get. Refer to https://www.hetzner.com/cloud for more information about server types."
  # cx11: 1vCPU, 2GM RAM, 20GB Disc
}


# Proxmox
variable "proxmox_api_password" {
  type = string
  description = "The password that is used for the proxmox authentication"
}

variable "proxmox_api_user" {
  type = string
  description = "The username and authentication provider used for the proxmox authentication. E.g. username@pve username@pam"
  default = "terraform@pve"
}

variable "proxmox_server_port" {
  description = "Proxmox server port (default 8006)"
  default = 8006
}

variable "proxmox_server_address" {
  description = "The Proxmox server address"
}

variable "proxmox_target_node" {
  type = string
  description = "The node where the VM should be created on."
}

variable "proxmox_vm_cidr" {
  type = string
  description = "The CIDR of the new VM. Example: 10.1.0.101/24 Warning: There is no conflict checking. Make sure to use only valid IP addresses."
}

variable "proxmox_vm_gateway" {
  type = string
  description = "The gateway of the new VM. Example: 10.1.0.1 Warning: There is no conflict checking. Make sure to use only valid IP addresses."
}

variable "proxmox_vm_name" {
  type = string
  description = "The hostname of the new VM. Has to be unique. Warning: There is no conflict check"
}

variable "proxmox_cpu_cores" {
  default = 2
}

variable "proxmox_memory" {
  default = 512
}
