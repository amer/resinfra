provider "proxmox" {
    pm_api_url = "https://${var.proxmox_server_address}:${var.proxmox_server_port}/api2/json"
    pm_user = var.proxmox_api_user
    pm_tls_insecure = "true"
    pm_password = var.proxmox_api_password
}

resource "random_id" "id" {
  byte_length = 4
}

resource "proxmox_vm_qemu" "proxmox_vm" {
  count             = var.instances
  name              = "${var.prefix}-proxmox-vm-${count.index+1}-${random_id.id.hex}"
  target_node       = var.proxmox_target_node
  clone             = "debian-cloudinit"
  os_type           = "cloud-init"
  cores             = 2
  sockets           = "1"
  cpu               = "host"
  memory            = 2048
  scsihw            = "virtio-scsi-pci"
#  bootdisk          = "ide1"
  /*
  disk {
#    id              = 0
    size            = "10G"
    type            = "scsi"
    storage         = "local-lvm"
    iothread        = true
  }
  */
  # private network
  network {
    model           = "virtio"
    bridge          = "vmbr1"
    // When not setting the macaddress manual it will be the same as the second interface and nothing will work
    macaddr = "00:${format("%02X",count.index+1)}:00:00:00:AA"
  }
  # public network
  network {
    model           = "virtio"
    bridge          = "vmbr2"
    // When not setting the macaddress manual it will be the same as the second interface and nothing will work
    macaddr = "00:${format("%02X",count.index+1)}:00:00:00:AB"
  }
  # Terraform does strange things on re-apply when we don't ignore changes here
  lifecycle {
    ignore_changes  = [
      disk,network,
    ]
  }
# Cloud Init Settings
  # count.index + 1 - skip blocked ip by proxmox gateway .1
  # count.index + 2 - skip blocked ip by local gateway  .2
  # count.index + 3 - start from here .3
  ipconfig0 = "ip=${cidrhost(var.proxmox_vm_subnet_cidr,count.index + 3)}/24,gw=${var.proxmox_private_gateway_address}"
  # count.index + 1 - skip blocked ip by proxmox gateway  .33
  # count.index + 2 - skip blocked ip by local gateway  .34
  # count.index + 3 - start from here .35
  ipconfig1 = "ip=${cidrhost(var.proxmox_public_ip_cidr,count.index + 3)}/29,gw=${var.proxmox_server_address}"
  sshkeys = file(var.path_public_key)
  ciuser = var.vm_username
}


resource "proxmox_vm_qemu" "gateway" {
  name              = "${var.prefix}-proxmox-gateway"
  target_node       = var.proxmox_target_node
  clone             = "debian-cloudinit"
  os_type           = "cloud-init"
  cores             = 2
  sockets           = "1"
  cpu               = "host"
  memory            = 2048
  scsihw            = "virtio-scsi-pci"
  #  bootdisk          = "ide1"
  /*
  disk {
#    id              = 0
    size            = "10G"
    type            = "scsi"
    storage         = "local-lvm"
    iothread        = true
  }
  */
  # private network
  network {
    #   id              = 0
    model           = "virtio"
    bridge          = "vmbr1"
    // When not setting the macaddress manual it will be the same as the second interface and nothing will work
    macaddr = "00:00:00:00:00:AA"
  }
  # public network
  network {
    #   id              = 1
    model           = "virtio"
    bridge          = "vmbr2"
    // When not setting the macaddress manual it will be the same as the second interface and nothing will work
    macaddr = "00:00:00:00:00:AB"
  }
  # Terraform does strange things on re-apply when we don't ignore changes here
  lifecycle {
    ignore_changes  = [
      disk,network,
    ]
  }
  # Cloud Init Settings
  # Give gateway vm ip .2 in private network
  ipconfig0 = "ip=${cidrhost(var.proxmox_vm_subnet_cidr,2)}/24,gw=${var.proxmox_private_gateway_address}"
  # Give gateway vm ip .33 in public network
  ipconfig1 = "ip=${cidrhost(var.proxmox_public_ip_cidr,2)}/29,gw=${var.proxmox_server_address}"
  sshkeys = file(var.path_public_key)
  ciuser = var.vm_username
}
