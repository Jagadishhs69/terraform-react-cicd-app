module "vpc" {
  source = "../../modules/vpc"
  env    = var.env
  cidr   = var.vpc_cidr
  azs    = var.azs
}

module "alb" {
  source            = "../../modules/alb"
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "ecr" {
  source = "../../modules/ecr"
  env    = var.env
}

module "asg" {
  source             = "../../modules/asg"
  env                = var.env
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_sg_id          = module.alb.alb_sg_id
  tg_arn             = module.alb.tg_arn
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  desired_capacity   = var.desired_capacity
  min_size           = var.min_size
  max_size           = var.max_size
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
