variable "hcloud_token" {}

variable "prefix" {default = "ri"}

variable "path_public_key" {}
variable "path_private_key" {}

variable "num_vms" {default = 9}

variable "volume_size" {
  default = 50
}

variable "location" {
  default = "nbg1"
}

variable "server_type" {
  default     = "cpx31"
  description = "server type to get. Refer to https://www.hetzner.com/cloud for more information about server types."
  # cx11: 1vCPU, 2GM RAM, 20GB Disc
}

