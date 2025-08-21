resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name  # Use ec2_profile, not app
  user_data              = data.template_cloudinit_config.userdata.rendered
  tags = {
    Name = "${var.env}-app-ec2"
  }
}

# IAM for EC2: ECR, CloudWatch Logs, SSM
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

resource "aws_iam_role_policy_attachment" "ssm_managed_core" {
  role       = aws_iam_role.ec2_role.name  # Combine roles
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "cw_logs" {
  name = "${var.env}-cw-logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"],
      Resource = "*"
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

locals {
  log_group = "/${var.env}/react-app"
}

data "template_cloudinit_config" "userdata" {
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      set -euo pipefail

      exec > >(tee -a /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

      # Update system
      apt-get update -y

      # Install Docker
      echo "Installing Docker"
      apt-get install -y docker.io || true
      systemctl enable docker || true
      systemctl start docker || true
      usermod -a -G docker ubuntu || true

      # Install AWS CLI v2
      echo "Installing AWS CLI v2"
      apt-get install -y unzip curl || true
      curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip -o awscliv2.zip
      ./aws/install || true

      # Install & enable SSM Agent
      echo "Installing SSM Agent"
      snap install amazon-ssm-agent --classic || true
      systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
      systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service || true

      # # Deploy Docker container
      # REGION="${var.region}"
      # ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
      # ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
      # IMAGE="${var.ecr_repo_url}:latest"
      # CONTAINER="react-app"

      # echo "Logging into ECR..."
      # aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

      # echo "Stopping old container if exists..."
      # docker rm -f $CONTAINER || true

      # echo "Pulling latest image..."
      # docker pull $IMAGE

      # echo "Running new container..."
      # docker run -d --name $CONTAINER -p 80:80 \
      #   --log-driver awslogs \
      #   --log-opt awslogs-region=$REGION \
      #   --log-opt awslogs-group=${local.log_group} \
      #   --log-opt awslogs-create-group=true \
      #   $IMAGE
          EOF
  }
}