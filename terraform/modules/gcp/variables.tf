variable "gcp_service_account_path" {}
variable "gcp_project_id" {}
variable "gcp_region" {}

variable "instances" {}

variable "prefix" {}

variable "gcp_subnet_cidr"  {}
variable "azure_subnet_cidr" {}
variable "hetzner_subnet_cidr" {}
variable "proxmox_subnet_cidr" {}

variable "azure_gateway_ipv4_addresses" {}
variable "hetzner_gateway_ipv4_address" {}
variable "proxmox_gateway_ipv4_address" {}

variable "gcp_asn" {}
variable "azure_asn" {}

variable "gcp_bgp_peer_address" {}
variable "azure_bgp_peer_address" {}
variable "ha_vpn_tunnel_count" {}

variable "shared_key" {}

variable "path_public_key" {}