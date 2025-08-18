variable "env"                { type = string }
variable "region"             { type = string }
variable "vpc_id"             { type = string }
variable "alb_sg_id"          { type = string }
variable "tg_arn"             { type = string }
variable "ami_id"             { type = string }
variable "instance_type"      { type = string }
variable "desired_capacity"   { type = number }
variable "min_size"           { type = number }
variable "max_size"           { type = number }
variable "ecr_repo_url"       { type = string } # module.ecr.repository_url
variable "ssh_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "private_subnet_ids" {
  type    = list(string)
  default = []
}

