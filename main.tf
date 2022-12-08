module "project" {
    source              = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v13.0.0"
    name                =  var.project_id
    billing_account     = var.billing_account
    parent              = var.parent_org
    services = [
    "compute.googleapis.com"
    ]
}

provider "google" { 
  project = var.project_id
  region = "us-central1"
}

module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 5.2"
  project_id   = module.project.project_id
  network_name = "default-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  subnets = [
    {
      subnet_name   = var.subnet_frontend
      subnet_ip     = var.network_cidr_frontend
      subnet_region = var.region
    },
    {
      subnet_name   = var.subnet_backend
      subnet_ip     = var.network_cidr_backend
      subnet_region = var.region
    }
  ]
  depends_on = [module.project.name]
}

resource "google_compute_router" "router" {
  project = module.project.project_id
  name    = "default-router"
  region  = var.region
  network = module.vpc.network_id
  bgp {
    asn = 64514
  }
  depends_on = [module.vpc]
}

resource "google_compute_router_nat" "nat" {
    project = module.project.project_id
    name                               = "default-router-nat"
    router                             = google_compute_router.router.name
    region                             = var.region
    nat_ip_allocate_option             = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

    log_config {
    enable = true
    filter = "ERRORS_ONLY"
    }
}

resource "google_compute_firewall" "allow-ssh" {
    project = module.project.project_id
    name = "allow-ssh"
    network = module.vpc.network_name
    priority = 1000
    direction = "INGRESS"
    disabled = false
    source_ranges = ["0.0.0.0/0"]
    target_tags =  [ var.network_tags ]
    allow {
    protocol = "tcp"
    ports    = ["22"]
    }
}
# output "gce_service_account" {
#     value = module.project.service_accounts.default.compute
# }

variable "project_id" { 
    default = "default-1669681950"
}

variable "subnet_frontend" { 
    default = "frontend"
}
variable "network_cidr_frontend" { 
    default = "192.168.10.0/24"
}

variable "subnet_backend" { 
    default = "backend"
}
variable "network_cidr_backend" { 
    default = "192.168.20.0/24"
}

variable "region" {
    default = "us-central1"
}

variable "zone" {
    default = "us-central1-a"
}

variable "billing_account" {
}

variable "parent_org" {
}

variable "network_tags" {
    default = "web"
}

