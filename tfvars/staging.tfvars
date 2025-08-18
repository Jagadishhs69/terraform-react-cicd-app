env                = "staging"
region             = "ap-south-1"
vpc_cidr           = "10.0.0.0/16"
azs                = ["ap-south-1a","ap-south-1b"]

ami_id             = "ami-0f918f7e67a3323f0"   # Ubuntu 22.04 in ap-south-1 (verify)
instance_type      = "t3.micro"
desired_capacity   = 2
min_size           = 1
max_size           = 3

ssh_cidr_blocks    = ["YOUR.IP.ADDR.0/24"]     # or []

log_retention_days = 14
cpu_high_threshold = 80
alb_5xx_threshold  = 5
create_sns         = false
alert_email        = ""
