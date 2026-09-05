terraform {
  backend "s3" {
    bucket         = "cloudops-terraform-state-sujal"
    key            = "auto-healing/terraform.tfstate"
    region         = "ap-south-1"
  }
}