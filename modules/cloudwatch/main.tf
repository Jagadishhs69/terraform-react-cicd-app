# Log group used by docker awslogs driver
resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.env}/react-app"
  retention_in_days = var.log_retention_days
  tags = { Name = "${var.env}-app-logs" }
}

# ALB 5xx alarm (ALB dimension needs arn_suffix)
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.env}-alb-5xx"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = var.alb_5xx_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = { LoadBalancer = var.alb_arn_suffix }
}

# Optional SNS for notifications
resource "aws_sns_topic" "alerts" {
  count = var.create_sns ? 1 : 0
  name  = "${var.env}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.create_sns && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# High CPU alarm (basic EC2 fleet signal)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.env}-cpu-high"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = var.cpu_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = var.create_sns ? [aws_sns_topic.alerts[0].arn] : null
  ok_actions          = var.create_sns ? [aws_sns_topic.alerts[0].arn] : null
}
