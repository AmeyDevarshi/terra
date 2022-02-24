resource "google_compute_address" "static1" {
  name = "ipv4-address1"
}

//create vm instance1 with group network
resource "google_compute_instance" "vm_instance1" {
  name         = "${var.name}-vm1"
  machine_type = "e2-small"
  allow_stopping_for_update = true

  deletion_protection=true

  tags = ["jenkins"]

  labels = {
    environment = "${var.env}"
    business_code="${var.school}"
  }

  metadata = {
    foo  = "bar"
    fizz = "buzz"
    "13" = "42"
  }

  boot_disk {
    initialize_params {
      image = "ansible-server-instance"
      size=40
      type = "pd-standard"
    }
  }

  network_interface {
    network = google_compute_network.group_vpc.id
    subnetwork = google_compute_subnetwork.group_subnet.id
    //network="default"
    access_config {
      nat_ip = google_compute_address.static1.address
    }
 }
}

//create instance group
resource "google_compute_instance_group" "instance_groups" {
  name        = "${var.name}-group"
  description = "Terraform instance group"
  zone        = "${var.zone}"
  network     = google_compute_network.group_vpc.id
  instances = [
    google_compute_instance.vm_instance1.id,
  ]
  
  named_port {
    name = "http"
    port = "8080"
  }

  named_port {
    name = "https"
    port = "8443"
  }
}

// group vpc creation
resource "google_compute_network" "group_vpc" {
  name = "${var.name}-vpc"
  auto_create_subnetworks = "false"
}

//group subnetwork
resource "google_compute_subnetwork" "group_subnet" {
  name                    = "${var.name}-subnet"
  ip_cidr_range           = "${var.subnet_cidr1}"
  network                 = google_compute_network.group_vpc.id
  region                  = "${var.region}"
}

//group firewall
resource "google_compute_firewall" "group_fairewall" {
  name                    = "${var.name}-firewall"
  network                 = google_compute_network.group_vpc.id

  allow {
    protocol              = "icmp"
  }

  allow {
    protocol              = "tcp"
    ports                 = ["22"]
  }
  target_tags = ["allow-health-check"]
  source_ranges            = ["0.0.0.0/0"]
}


//create vpc1
resource "google_compute_network" "vpc1" {
  name                    = "${var.name}-vpc1"
  auto_create_subnetworks = "false" 
}

//create subnet1
resource "google_compute_subnetwork" "subnet1" {
  name                    = "${var.name}-subnet1"
  ip_cidr_range           = "${var.subnet_cidr2}"
  network                 = google_compute_network.vpc1.id
  region                  = "${var.region}"
}

//firewall1 configuration
resource "google_compute_firewall" "firewall1" {
  name                    = "${var.name}-firewall1"
  network                 = "${google_compute_network.vpc1.name}"

  allow {
    protocol              = "icmp"
  }

  allow {
    protocol              = "tcp"
    ports                 = ["22"]
  }
  source_ranges            = ["0.0.0.0/0"]
}

//network peering
resource "google_compute_network_peering" "peering1" {
  name         = "peering1"
  network      = google_compute_network.group_vpc.self_link
  peer_network = google_compute_network.vpc1.self_link
}

resource "google_compute_network_peering" "peering2" {
  name         = "peering2"
  network      = google_compute_network.vpc1.self_link
  peer_network = google_compute_network.group_vpc.self_link
}

//create health check
resource "google_compute_health_check" "health-check" {
  name = "terraform-health-check"

  timeout_sec        = 1
  check_interval_sec = 1
  tcp_health_check {
  port = "80"
  }
}

resource "google_compute_region_backend_service" "default" {
  name          = "backend-service"
  region        = "${var.region}"
  health_checks = [google_compute_health_check.health-check.id]
}

resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  name                  = "frontend-service"
  backend_service       = google_compute_region_backend_service.default.id
  region                = "${var.region}"
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  network               = google_compute_network.group_vpc.id
  subnetwork            = google_compute_subnetwork.group_subnet.id
}

resource "google_compute_backend_service" "backend-service" {
  name      = "health-check"
  port_name = "tcp"
  protocol  = "TCP"

  backend {
    group = google_compute_instance_group.instance_groups.id
  }

  health_checks = [
    google_compute_health_check.health-check.id,
  ]
}

//create cluster
resource "google_container_cluster" "terraform_cluster" {
  description = "Terraform GKE Cluster"
  project  = "${var.project_id}"
  name     = "${var.name}-cluster"
  location = "${var.zone}"
  network  = google_compute_network.group_vpc.id
  subnetwork = google_compute_subnetwork.group_subnet.id

  remove_default_node_pool = true 
  initial_node_count       = "${var.initial_node_count}"
}

//create node pool
resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "${var.name}-node"
  location   = "${var.zone}"
  cluster    = google_container_cluster.terraform_cluster.name
  node_count = 1
  
  node_config {
    preemptible  = true
    machine_type = "e2-small"
    labels = {
      foo = "bar"
    }
    tags = ["foo", "bar"]

  metadata = {
    disable-legacy-endpoints= "true"
  }
  }
}

//create gcr
resource "google_container_registry" "registry" {
  project = "${var.project_id}"
  location = "US"
}
