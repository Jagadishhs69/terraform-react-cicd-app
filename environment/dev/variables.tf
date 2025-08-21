variable "env"                { type = string }
variable "region"             { type = string }
variable "vpc_cidr"           { type = string }

variable "ami_id"             { type = string }
variable "instance_type"      { type = string }

# CloudWatch
variable "log_retention_days" { 
  type = number
  default = 14 
}
variable "cpu_high_threshold" { 
  type = number
  default = 80 
}
variable "alb_5xx_threshold"  { 
  type = number
  default = 5 
}
variable "create_sns" { 
  type = bool
  default = false 
}
variable "alert_email" { 
  type = string
  default = "" 
}

variable "azs"{ 
  type = list(string) 
  default = []
}

variable "ssh_cidr_blocks"{ 
  type = list(string)
  default = [] 
}