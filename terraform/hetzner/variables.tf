variable "hcloud_token" {
  default = null
}

variable "pub_ssh_path" {
  default = "~/.ssh/id_rsa.pub"
}

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

variable "os_type" {
  default = "ubuntu-20.04"
  description = "image to use to build the vm. Use standard or custom image."
  # standard images are:
  #  - ubuntu-16.04
  #  - debian-9
  #  - centos-7
  #  - ubuntu-18.04
  #  - debian-10
  #  - centos-8
  #  - ubuntu-20.04
  #  - fedora-32
  #  - fedora-33
}
