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



