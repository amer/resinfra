variable "public_key_path" {
  description = "path to public key that will be uploaded to aws"
  default     = "~/.ssh/id_rsa.pub"
}

variable "prefix" {
  default = "resinfra-mc"
}

variable "instances" {
  default = "1"
}

variable "username" {
  description = "username to be used among ALL providers. Don't choose admin or root."
}

# AWS
variable aws_access_key {}
variable aws_secret_key {}
variable aws_region {}


# Hetzner
variable "hcloud_token" {}

