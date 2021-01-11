output "gcp_gateway_ipv4_address" {
  value = google_compute_address.gateway_ip_address.address
}

