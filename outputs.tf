output "ip-ext" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
} 
output "ip-int" {
  value = google_compute_instance.vm_instance.network_interface.0.network_ip
}
