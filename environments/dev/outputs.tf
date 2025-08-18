output "vpc_id"       { value = module.vpc.vpc_id }
output "alb_dns_name" { value = module.alb.alb_dns_name }
output "asg_name"     { value = module.asg.asg_name }
output "ecr_repo"     { value = module.ecr.repository_url }
