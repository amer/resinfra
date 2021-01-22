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
  default = 8006
}

variable "proxmox_server_address" {
  default = "192.168.2.164"
}