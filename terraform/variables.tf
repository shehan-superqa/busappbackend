variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "bus-ticketing"
}

variable "droplet_image" {
  description = "Droplet image (OS)"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "droplet_region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}

variable "droplet_size" {
  description = "Droplet size"
  type        = string
  default     = "s-2vcpu-2gb" # $18/month - 2GB RAM, 50GB SSD, 2 vCPU - Better performance
}

variable "ssh_key_fingerprints" {
  description = "List of SSH key fingerprints to add to the droplet"
  type        = list(string)
  default     = []
}

variable "ssh_key_id" {
  description = "Name of existing SSH key (alternative to fingerprints)"
  type        = string
  default     = null
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"] # Change this for security
}

variable "db_url" {
  description = "MongoDB connection URL"
  type        = string
  sensitive   = true
}

variable "app_port" {
  description = "Express server port"
  type        = number
  default     = 3000
}

variable "tcp_port" {
  description = "TCP socket server port"
  type        = number
  default     = 8080
}

variable "node_env" {
  description = "Node.js environment"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Domain name (optional, leave empty to skip)"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository URL (optional, for auto-deployment)"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

