output "asg_name"               { value = "${var.env}-react-asg" }
output "instance_sg_id"         { value = "${var.env}-react-asg.id" }
output "asg_key_name"           { value = aws_key_pair.asg_key.key_name}
output "asg_private_key_path"   { value = local_file.asg_private_key.filename}
