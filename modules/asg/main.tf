# IAM for EC2: ECR & CloudWatch Logs
# Create new key pair
resource "tls_private_key" "asg_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "asg_key" {
  key_name   = "my-asg-key"
  public_key = tls_private_key.asg_key.public_key_openssh
}

# Save the private key locally (will create my-asg-key.pem file in root)
resource "local_file" "asg_private_key" {
  content  = tls_private_key.asg_key.private_key_pem
  filename = "${path.module}/my-asg-key.pem"
  file_permission = "0600"
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.env}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.env}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${var.env}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_managed_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_policy" "cw_logs" {
  name   = "${var.env}-cw-logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect: "Allow",
      Action: ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogStreams"],
      Resource: "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cw_logs.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.env}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# SG for instances: allow 80 from ALB, optional SSH from CIDRs
resource "aws_security_group" "ec2_sg" {
  name   = "${var.env}-ec2-sg"
  vpc_id = var.vpc_id
  

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  dynamic "ingress" {
    for_each = length(var.ssh_cidr_blocks) > 0 ? [1] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
    }
  }

  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

  tags = { Name = "${var.env}-ec2-sg" }
}

locals {
  log_group = "/${var.env}/react-app"
}

data "template_cloudinit_config" "userdata" {
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content = <<-EOF
      #!/bin/bash
      set -e

      # Update system
      apt-get update -y >> /var/log/user-data.log 2>&1

      # Install Docker
      echo "Installing Docker" >> /var/log/user-data.log
      apt-get install -y docker.io >> /var/log/user-data.log 2>&1
      systemctl enable docker >> /var/log/user-data.log 2>&1
      systemctl start docker >> /var/log/user-data.log 2>&1
      usermod -a -G docker ubuntu >> /var/log/user-data.log 2>&1

      # Install AWS CLI v2
      echo "Installing AWS CLI v2" >> /var/log/user-data.log
      apt-get install -y unzip curl >> /var/log/user-data.log 2>&1
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" >> /var/log/user-data.log 2>&1
      unzip awscliv2.zip >> /var/log/user-data.log 2>&1
      ./aws/install >> /var/log/user-data.log 2>&1

      # Install & enable SSM Agent (for Ubuntu via snap)
      echo "Installing SSM Agent" >> /var/log/user-data.log
      snap install amazon-ssm-agent --classic >> /var/log/user-data.log 2>&1
      systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service >> /var/log/user-data.log 2>&1
      systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service >> /var/log/user-data.log 2>&1

      REGION="${var.region}"
      ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
      ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

      # ECR login
      aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

      IMAGE="${var.ecr_repo_url}:latest"
      CONTAINER="react-app"

      # Stop old container if exists
      docker rm -f $CONTAINER || true

      # Pull & run with CloudWatch Logs
      docker pull $IMAGE
      docker run -d --name $CONTAINER -p 80:80 \
        --log-driver awslogs \
        --log-opt awslogs-region=$REGION \
        --log-opt awslogs-group=${local.log_group} \
        --log-opt awslogs-create-group=true \
        $IMAGE
    EOF
  }
}

resource "aws_launch_template" "lt" {
  name_prefix               = "${var.env}-react-lt-"
  image_id                  = var.ami_id
  instance_type             = var.instance_type
  key_name                  = aws_key_pair.asg_key.key_name
  vpc_security_group_ids    = [aws_security_group.ec2_sg.id]
  iam_instance_profile      { name = aws_iam_instance_profile.ec2_profile.name }
  user_data                 = data.template_cloudinit_config.userdata.rendered
  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.env}-react-ec2" }
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.env}-react-asg"
  vpc_zone_identifier       = var.private_subnet_ids
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  target_group_arns         = [var.tg_arn]
  health_check_type         = "EC2"
  health_check_grace_period = 90

  launch_template { 
    id = aws_launch_template.lt.id 
    version = "$Latest" 
  }

  tag { 
    key = "Name" 
    value = "${var.env}-react-ec2" 
    propagate_at_launch = true 
  }

  lifecycle { create_before_destroy = true }
}
