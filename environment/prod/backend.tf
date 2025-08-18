terraform {
  backend "s3" {
    bucket = "terraform-state-cicd-33993333"
    key = "terraform-state-cicd-33993333/prod/terraform.tfstate"
    region = "ap-south-1"
    encrypt = true
  
  }
}