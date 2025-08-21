terraform {
  backend "s3" {
    bucket = "terraform-state-cicd-33993333"
    key = "dev/terraform.tfstate"
    region = "ap-south-1"
    encrypt = true
  
  }
}