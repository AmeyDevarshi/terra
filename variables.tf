variable "credentials" {
    description = "GCP project service account key"
    type = string
    default="terraform_auth.json"
}

variable "project_id" {
    description = "GCP project id"
    type = string
    default="probable-skill-338014"
}

variable "region" {
    type = string
    default = "us-central1"
}

variable "zone" {
    type = string
    default = "us-central1-c"
}

variable "name" {
    description = "name of my first work"
    type = string
    default="terraform-1"
}

variable "subnet_cidr1" {
    description = "cidr range of 1st vpn's subnet"
    type = string
    default="10.2.0.0/16"
}

variable "subnet_cidr2" {
    description = "cidr range of 2nd vpn's subnet"
    type = string
    default="10.0.0.0/16"
}

variable "env" {
    default="teraform-env"
}

variable "school" {
    default="terraform-school"
}

variable "initial_node_count" {
    default = 1  
}
