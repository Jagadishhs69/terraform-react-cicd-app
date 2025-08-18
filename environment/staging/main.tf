module "vpc" {
  source              = "../modules/vpc"
  env                 = var.environment
  vpc_cidr            = var.staging_vpc_cidr
  public_subnet_cidrs = var.staging_public_subnet_cidrs
  private_subnet_cidrs = var.staging_private_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "dynamodb" {
  source = "../modules/dynamodb"
  env    = var.environment
}

module "ecr" {
  source = "../modules/ecr"
  env    = var.environment
}

module "secrets" {
  source      = "../modules/secrets"
  env         = var.environment
  db_username = var.db_username
  db_password = var.db_password
}

module "rds" {
  source            = "../modules/rds"
  env               = var.environment
  engine            = var.rds_engine
  engine_version    = var.rds_engine_version
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  db_username       = var.db_username
  db_password       = var.db_password
  security_group_id = module.vpc.security_group_id
  subnet_ids        = module.vpc.private_subnet_ids
}

module "ec2" {
  source             = "../modules/ec2"
  env                = var.environment
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_id  = module.vpc.security_group_id
  region             = var.region
  ecr_repository_url = module.ecr.repository_url
  rds_endpoint       = module.rds.rds_endpoint
}

module "cloudwatch" {
  source = "../modules/cloudwatch"
  env    = var.environment
}