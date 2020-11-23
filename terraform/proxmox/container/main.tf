terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.6.5"
    }
  }
  required_version = ">= 0.13.5"
}

provider "proxmox" {
    pm_api_url = "https://${var.proxmox_server_address}:${var.proxmox_server_port}/api2/json"
    pm_user = var.proxmox_api_user
    pm_tls_insecure = "true"
    pm_password = var.proxmox_api_password
}

resource "proxmox_lxc" "lxc-test" {
    hostname = "lxc-test-host"
    cores = 1
    memory = "1024"
    swap = "2048"
    network {
        name = "eth0"
        bridge = "vmbr0"
        ip = "192.168.2.101/24"
    }
    ostemplate = "local:vztmpl/debian-10.0-standard_10.0-1_amd64.tar.gz"
    target_node = "target_node"
    unprivileged = false
}