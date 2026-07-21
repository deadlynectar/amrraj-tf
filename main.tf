terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "project-8db97ec3-fe82-4144-8d4"
  region  = "asia-south1"
  zone    = "asia-south1-a"
}

resource "google_compute_network" "vpc_network" {
  name = "my-tf-vpc"
}

resource "google_compute_instance" "vm_instance" {
  name         = "my-tf-instance"
  machine_type = "e2-small"
  zone         = "asia-south1-a"
  tags         = ["web", "dev"]

  metadata = {
    ssh-keys = "amritraj:${file("~/.ssh/gcp_key.pub")}"
  }
  # CRITICAL: This bash script automatically executes as 'root' on initial boot
  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Update system package manager repository definitions
    apt-get update
    
    # Install Nginx silently without prompting for user confirmation
    apt-get install -y nginx
    
    # Start the Nginx daemon process
    systemctl start nginx
    
    # Configure Nginx to automatically launch during system system boot cycles
    systemctl enable nginx
  EOT
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.id
    access_config {}
  }
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-port-80-tf"
  network = google_compute_network.vpc_network.id
  # Allow incoming traffic
  direction = "INGRESS"
  # Match traffic from any IP address
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # CRITICAL: This rule only applies to VMs with this exact tag
  target_tags = ["web"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-port-22-tf"
  network = google_compute_network.vpc_network.id
  # Allow incoming traffic
  direction = "INGRESS"
  # Match traffic from any IP address
  source_ranges = ["171.76.80.180/32"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # CRITICAL: This rule only applies to VMs with this exact tag
  target_tags = ["dev"]
}