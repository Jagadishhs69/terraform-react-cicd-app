variable "env" {
  type = string
}

variable "instance_id" {
  description = "EC2 instance ID to monitor"
  type        = string
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "cpu_high_threshold" {
  type    = number
  default = 80
}

variable "create_sns" {
  type    = bool
  default = false
}

variable "alert_email" {
  type    = string
  default = ""
}