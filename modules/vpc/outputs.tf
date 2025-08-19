output "vpc_id" {
  value       = aws_vpc.appvpc.id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value       = [for s in values(aws_subnet.public) : s.id]
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value       = [for s in values(aws_subnet.private) : s.id]
  description = "List of private subnet IDs"
}

