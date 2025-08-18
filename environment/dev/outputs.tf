output "vpc_id"       { value = module.vpc.vpc_id }
output "alb_dns_name" { value = module.alb.alb_dns_name }
output "ecr_repo"     { value = module.ecr.repository_url }
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.asg_name
}

