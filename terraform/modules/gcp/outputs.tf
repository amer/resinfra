output "gcp_gateway_ipv4_address" {
  value = google_compute_address.gateway_ip_address.address
}

output "gcp_ha_gateway_interfaces" {
  value = google_compute_ha_vpn_gateway.main.vpn_interfaces
}

output "gcp_private_ip_addresses" {
  value = google_compute_instance.worker_vm.*.network_interface.0.network_ip
}

output "public_ip_addresses" {
  value = google_compute_instance.worker_vm.*.network_interface.0.access_config.0.nat_ip
}
