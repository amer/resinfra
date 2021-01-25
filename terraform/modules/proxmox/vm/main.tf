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
  clone             = "debian-cloudinit-10G"
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

  /* There are 2 things that have to be changed in order to get it work correctly
        1. install ansible dependencies for docker deployment
        2. change the default root to the private network

    to 1: Ansible can not run properly on the proxmox image because the python-apt package is not installed by default
          So we have to "manually" install it on the machine

    to 2: The default route seems to be randomly picked from the public or private network.
          It currently only works as intended when the private ip of the proxmox machine is picked as the default route.
          This gets enforced by executing "sudo ip route replace default via 10.4.0.1 dev eth0 onlink"
  */
  provisioner "remote-exec" {
    inline = ["echo 'SSH is now ready!'", "echo 'Wait 30 sec to ensure init phase is finished'", "sleep 30",
              "echo 'Install pytho3-apt dependency'", "sudo apt install python3-apt -y",
              "echo 'Setting default gateway to 10.4.0.1'", "sudo ip route replace default via 10.4.0.1 dev eth0 onlink"]

    connection {
      type        = "ssh"
      user        = var.vm_username
      private_key = file(var.path_private_key)
      host        = cidrhost(var.proxmox_public_ip_cidr,count.index + 3)
    }
  }



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

locals {
  gateway_public_ipv4_address = regex("\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b", proxmox_vm_qemu.gateway.ipconfig1)
  gateway_private_ipv4_address = regex("\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b", proxmox_vm_qemu.gateway.ipconfig0)
}


resource "null_resource" "strongswan_ansible" {

  triggers = {
    gateway_recreation_trigger = proxmox_vm_qemu.gateway.id
  }

  provisioner "remote-exec" {
    inline = ["echo 'SSH is now ready!'"]

    connection {
      type        = "ssh"
      user        = var.vm_username
      private_key = file(var.path_private_key)
      host        = local.gateway_public_ipv4_address
    }
  }

  provisioner "local-exec" {
    command = <<EOF
        ansible-playbook -i '${local.gateway_public_ipv4_address},'  \
            -u '${var.vm_username}' ${abspath(path.module)}/../../../../ansible/libreswan_playbook.yml \
            --ssh-common-args='-o StrictHostKeyChecking=no' \
            --extra-vars 'public_gateway_ip='${local.gateway_public_ipv4_address}' \
                          local_gateway_ip='${local.gateway_private_ipv4_address}' \
                          local_cidr='${var.proxmox_vm_subnet_cidr}' \
                          azure_remote_gateway_ip='${var.azure_gateway_ipv4_address}' \
                          azure_remote_cidr='${var.azure_vm_subnet_cidr}'
                          gcp_remote_gateway_ip='${var.gcp_gateway_ipv4_address}' \
                          gcp_remote_cidr='${var.gcp_vm_subnet_cidr}' \
                          other_strongswan_gateway_ip=${var.hetzner_gateway_ipv4_address} \
                          other_strongswan_remote_cidr=${var.hetzner_vm_subnet_cidr} \
                          psk='${var.shared_key}'' \
            --key-file '${var.path_private_key}'
  EOF
  }
}