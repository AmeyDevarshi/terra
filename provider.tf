//configure the google cloud provider
provider "google" {
  credentials = "${file("${var.credentials}")}"
  project = "${var.project_id}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}
