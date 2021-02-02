variable "hcloud_token" {}
variable "client_id" {}
variable "client_secret" {}
variable "subscription_id" {}
variable "gcp_project_id" {}
variable "gcp_region" {}
variable "gcp_service_account_path" {}
variable "tenant_id" {}
variable "shared_key" {}
variable "proxmox_api_password" {}
variable "proxmox_api_user" {}

variable "proxmox_server_port" { default = 8006 }
variable "proxmox_server_address" { default = "92.204.175.162" }
variable "proxmox_target_node" { default = "host1" }
variable "proxmox_private_gateway_address" { default = "10.4.0.1" }

variable "vpc_cidr" { default = "10.0.0.0/8" }
variable "prefix" { default = "ri" }
variable "instances" { default = "2" }
variable "vm_username" { default = "resinfra" }

variable "git_checkout_branch" { default = "dev_jan" }
