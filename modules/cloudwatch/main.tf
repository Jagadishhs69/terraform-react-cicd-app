resource "aws_sns_topic" "alarm_topic" {
  name  = "${var.env}-alarm-topic"
  count = var.create_sns ? 1 : 0
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.create_sns && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarm_topic[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.env}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "Alarm when EC2 CPU exceeds ${var.cpu_high_threshold}%"
  dimensions = {
    InstanceId = var.instance_id
  }
  alarm_actions     = var.create_sns ? [aws_sns_topic.alarm_topic[0].arn] : []
  treat_missing_data = "notBreaching"
}

# Memory Utilization Alarm (requires CloudWatch Agent)
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.env}-ec2-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when EC2 memory exceeds 80%"
  dimensions = {
    InstanceId = var.instance_id
  }
  alarm_actions     = var.create_sns ? [aws_sns_topic.alarm_topic[0].arn] : []
  treat_missing_data = "notBreaching"
}

# Docker Container Stop/Exit Alarm (custom metric)
resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "/${var.env}/react-app"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_metric_alarm" "container_exit" {
  alarm_name          = "${var.env}-docker-container-exit"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ContainerExits"
  namespace           = "Custom/Docker"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm when Docker container stops or exits"
  dimensions = {
    InstanceId = var.instance_id
  }
  alarm_actions     = var.create_sns ? [aws_sns_topic.alarm_topic[0].arn] : []
  treat_missing_data = "notBreaching"
}