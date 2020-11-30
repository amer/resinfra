variable "pub_ssh_path" {
  default = "~/.ssh/id_rsa.pub"
}

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
  decription = "The Proxmox server address"
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
