output "staging_instance_id" {
  value = module.ec2.instance_id
}

output "staging_instance_public_ip" {
  value = module.ec2.instance_public_ip
}

output "staging_rds_endpoint" {
  value = module.rds.rds_endpoint
}