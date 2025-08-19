resource "aws_security_group" "alb_sg" {
  name        = "${var.env}-alb-sg"
  description = "ALB SG"
  vpc_id      = var.vpc_id

  ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
  
  tags = { Name = "${var.env}-alb-sg" }
}

resource "aws_lb" "applb" {
  name               = "${var.env}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
  idle_timeout       = 60
  tags = { Name = "${var.env}-alb" }
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.env}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path                = "/"
    enabled             = true
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = { Name = "${var.env}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.applb.arn
  port              = 80
  protocol          = "HTTP"
  default_action { 
    type = "forward" 
    target_group_arn = aws_lb_target_group.tg.arn 
  }
}
