terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "=3.50.0"
    }
  }
}

provider "google" {}

resource "google_project" "main" {
  name       = "Resinfra Project - Test"
  project_id = var.project_id
  org_id     = var.organization_id
}
