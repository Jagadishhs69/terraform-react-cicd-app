variable "env"{ 
    type = string 
}
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
variable "alb_arn_suffix"     { 
    type = string 
}
variable "create_sns"         { 
    type = bool
    default = false 
}
variable "alert_email"        { 
    type = string
    default = "" 
}
