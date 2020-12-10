provider "proxmox" {
    pm_api_url = "https://${var.proxmox_server_address}:${var.proxmox_server_port}/api2/json"
    pm_user = var.proxmox_api_user
    pm_tls_insecure = "true"
    pm_password = var.proxmox_api_password
}

resource "proxmox_vm_qemu" "proxmox_vm" {
  count             = var.instances
  name              = "${var.prefix}-vm-${count.index+1}"
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
#  cicustom = "user=local:snippets/cloud_init_deb10_vm.yml"
  ipconfig0 = "ip=10.1.0.10${count.index+1}/24,gw=10.1.0.1"
  sshkeys = file(var.public_key_path)
  ciuser = var.username
}

output "proxmox_private_ip" {
  value = {
    for server in proxmox_vm_qemu.proxmox_vm :
    server.name => server.ipconfig0
  }
  description = "The private IP address of the proxmox instance."
}