variable "env" { type = string }
variable "region" { type = string }
variable "vpc_id" { type = string }
variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "ecr_repo_url" { type = string }
variable "ssh_cidr_blocks" {
  type    = list(string)
  default = []
}
variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}
variable "security_group_id" {
  description = "Security group ID for the EC2 instance"
  type        = string
}