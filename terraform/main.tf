# Alternative Terraform configuration using Docker deployment
# To use this, rename main.tf to main-original.tf and this file to main.tf

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# Create Droplet with Docker deployment
resource "digitalocean_droplet" "app_server" {
  image    = var.droplet_image
  name     = "${var.project_name}-server"
  region   = var.droplet_region
  size     = var.droplet_size
  ssh_keys = var.ssh_key_fingerprints

  user_data = templatefile("${path.module}/user-data-docker.sh", {
    db_url        = var.db_url
    port          = var.app_port
    tcp_port      = var.tcp_port
    node_env      = var.node_env
    project_name  = var.project_name
    github_repo   = var.github_repo
    github_branch = var.github_branch
    domain_name   = var.domain_name
  })

  tags = [var.project_name]
}

# Create firewall and attach to droplet
resource "digitalocean_firewall" "app_firewall" {
  name = "${var.project_name}-firewall"

  droplet_ids = [digitalocean_droplet.app_server.id]

  # Allow SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_ssh_ips
  }

  # Allow HTTP (Express API)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "3000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow TCP Socket Server
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8080"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Create domain and DNS record (optional)
resource "digitalocean_domain" "app_domain" {
  count      = var.domain_name != "" ? 1 : 0
  name       = var.domain_name
  ip_address = digitalocean_droplet.app_server.ipv4_address
}

resource "digitalocean_record" "app_record" {
  count  = var.domain_name != "" ? 1 : 0
  domain = digitalocean_domain.app_domain[0].name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.app_server.ipv4_address
  ttl    = 3600
}

