terraform {
  backend "gcs" {
    bucket  = "resinfra-tf-state"
    credentials = ""
  }
}
