# General - these will be used among cloud providers
variable "public_key_path" {
  description = "path to public key that will be uploaded to aws"
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "path to private key, used to access instance"
  default     = "~/.ssh/id_rsa"
}

variable "prefix" {
  default = "resinfra"
}

# Cloud provider specific variables

# Azure
variable resinfra_subscription_id {}

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

variable "os_type" {
  default = "ubuntu-20.04"
  description = "image to use to build the vm. Use standard or custom image."
}
