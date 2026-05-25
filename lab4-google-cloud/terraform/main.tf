terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "YOUR_PROJECT_ID"
}

provider "google" {
  project = var.project_id
  region  = "europe-central2"
  zone    = "europe-central2-a"
}

resource "google_compute_network" "vpc_network" {
  name                    = "lab4-network"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "lab4-allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_internal_db" {
  name    = "lab4-allow-internal-db"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_tags = ["web-server"]
  target_tags = ["db-server"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "lab4-allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_instance" "db" {
  name         = "db-node"
  machine_type = "e2-micro"
  tags         = ["db-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  metadata = {
    user-data = file("${path.module}/cloud_init.yml")
  }
}

resource "google_compute_instance" "worker" {
  name         = "worker-node"
  machine_type = "e2-micro"
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  metadata = {
    user-data = file("${path.module}/cloud_init.yml")
  }
}

output "worker_public_ip" {
  value = google_compute_instance.worker.network_interface.0.access_config.0.nat_ip
}

output "db_public_ip" {
  value = google_compute_instance.db.network_interface.0.access_config.0.nat_ip
}

output "db_internal_ip" {
  value = google_compute_instance.db.network_interface.0.network_ip
}