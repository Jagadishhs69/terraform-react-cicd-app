provider "aws" {
  region = var.region
}

# terraform {
#   backend "s3" {
#     bucket = "your-terraform-state-bucket"
#     key    = "dev/terraform.tfstate"
#     region = "ap-south-1"
#   }
# }

module "vpc" {
  source = "../../modules/vpc"
  env    = var.env
  cidr   = var.vpc_cidr
  azs    = var.azs
}

module "ecr" {
  source = "../../modules/ecr"
  env    = var.env
}

resource "aws_security_group" "app_sg" {
  name   = "${var.env}-app-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.env}-app-sg" }
}

module "ec2" {
  source            = "../../modules/ec2"
  env               = var.env
  region            = var.region
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = aws_security_group.app_sg.id
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  ecr_repo_url      = module.ecr.repository_url
  ssh_cidr_blocks   = var.ssh_cidr_blocks
}

module "cloudwatch" {
  source             = "../../modules/cloudwatch"
  env                = var.env
  instance_id        = module.ec2.instance_id
  log_retention_days = var.log_retention_days
  cpu_high_threshold = var.cpu_high_threshold
  create_sns         = var.create_sns
  alert_email        = var.alert_email
}