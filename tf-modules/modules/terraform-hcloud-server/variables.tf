variable hcloud_token{}
variable random_id{}
variable prefix{}
variable public_key_path{}
variable instances{}
variable user_data{}

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
  default = "cx11"
  description = "server type to get. Refer to https://www.hetzner.com/cloud for more information about server types."
  # cx11: 1vCPU, 2GM RAM, 20GB Disc
}
