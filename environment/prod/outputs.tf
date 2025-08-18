output "prod_instance_id" {
  value = module.ec2.instance_id
}

output "prod_instance_public_ip" {
  value = module.ec2.instance_public_ip
}

output "prod_rds_endpoint" {
  value = module.rds.rds_endpoint
}