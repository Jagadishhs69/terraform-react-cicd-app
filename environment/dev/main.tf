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

module "ec2" {
  source             = "../../modules/ec2"
  env                = var.env
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  ecr_repo_url       = module.ecr.repository_url
  ssh_cidr_blocks    = var.ssh_cidr_blocks
}

module "cloudwatch" {
  source              = "../../modules/cloudwatch"
  env                 = var.env
  log_retention_days  = var.log_retention_days
  cpu_high_threshold  = var.cpu_high_threshold
  alb_5xx_threshold   = var.alb_5xx_threshold
  alb_arn_suffix      = module.alb.alb_arn_suffix
  create_sns          = var.create_sns
  alert_email         = var.alert_email
}
