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

variable "server_type" {
  default = "CX31"
  description = "server type to get. Refer to https://www.hetzner.com/cloud for more information about server types."
  # cx11: 1vCPU, 2GM RAM, 20GB Disc
}

variable "prefix" {
  default = "resinfra-mc"
}

variable "instances" {
  default = "1"
}
