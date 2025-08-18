# IAM for EC2: ECR & CloudWatch Logs
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

  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
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

      apt-get update -y
      apt-get install -y docker.io awscli
      systemctl enable docker
      systemctl start docker

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

  launch_template { id = aws_launch_template.lt.id version = "$Latest" }

  tag { key = "Name" value = "${var.env}-react-ec2" propagate_at_launch = true }

  lifecycle { create_before_destroy = true }
}
