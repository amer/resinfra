variable "hcloud_token" {}
variable "client_id" {}
variable "client_secret" {}
variable "subscription_id" {}
variable "gcp_project_id" {}
variable "gcp_region" {}
variable "gcp_service_account_path" {}
variable "tenant_id" {}
variable "shared_key" {}

variable "vpc_cidr" {default = "10.0.0.0/8"}
variable "prefix" {default = "ri"}
variable "instances" {default = "2"}
