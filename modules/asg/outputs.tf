output "asg_name"       { value = aws_autoscaling_group.asg.name }
output "instance_sg_id" { value = aws_security_group.ec2_sg.id }
