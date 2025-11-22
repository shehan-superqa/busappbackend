output "droplet_ip" {
  description = "Public IP address of the droplet"
  value       = digitalocean_droplet.app_server.ipv4_address
}

output "droplet_id" {
  description = "ID of the droplet"
  value       = digitalocean_droplet.app_server.id
}

output "app_url" {
  description = "Application URL"
  value       = "http://${digitalocean_droplet.app_server.ipv4_address}:3000"
}

output "tcp_endpoint" {
  description = "TCP socket endpoint"
  value       = "${digitalocean_droplet.app_server.ipv4_address}:8080"
}

output "domain_url" {
  description = "Domain URL (if configured)"
  value       = var.domain_name != "" ? "http://${var.domain_name}:3000" : null
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${digitalocean_droplet.app_server.ipv4_address}"
}

