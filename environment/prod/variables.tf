variable "environment" {
  description = "The production environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "prod_vpc_cidr" {
  description = "CIDR block for prod VPC"
  type        = string
}

variable "prod_public_subnet_cidrs" {
  description = "CIDR blocks for prod public subnets"
  type        = list(string)
}

variable "prod_private_subnet_cidrs" {
  description = "CIDR blocks for prod private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "rds_engine" {
  description = "RDS engine"
  type        = string
}

variable "rds_engine_version" {
  description = "RDS engine version"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
}

variable "db_username" {
  description = "RDS database username"
  type        = string
}

variable "db_password" {
  description = "RDS database password"
  type        = string
}