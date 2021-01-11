output "gcp_gateway_ipv4_address" {
  value = google_compute_address.gateway_ip_address.address
}

output "gcp_public_ip_addresses" {
  value = google_compute_instance.vm.network_interface.0.*.network_ip
}
