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


resource "proxmox_vm_qemu" "proxmox_vm" {
  name              = var.proxmox_vm_name
  target_node       = var.proxmox_target_node
  clone             = "debian-cloudinit"
  os_type           = "cloud-init"
  cores             = var.proxmox_cpu_cores
  sockets           = "1"
  cpu               = "host"
  memory            = var.proxmox_memory
  scsihw            = "virtio-scsi-pci"
  bootdisk          = "virtio0"
  disk {
#    id              = 0
    size            = "10G"
    type            = "scsi"
    storage         = "local-lvm"
    iothread        = true
  }
  network {
#    id              = 0
    model           = "virtio"
    bridge          = "vmbr1"
  }
  lifecycle {
    ignore_changes  = [
      network,
    ]
  }
# Cloud Init Settings
  ipconfig0 = "ip=${var.proxmox_vm_cidr},gw=${var.proxmox_vm_gateway}"
  sshkeys = file(var.pub_ssh_path)
  ciuser = "root"
}
