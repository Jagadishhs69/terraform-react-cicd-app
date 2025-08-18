output "alb_dns_name"    { value = aws_lb.this.dns_name }
output "alb_sg_id"       { value = aws_security_group.alb_sg.id }
output "tg_arn"          { value = aws_lb_target_group.tg.arn }
output "alb_arn_suffix"  { value = aws_lb.this.arn_suffix }   # For CloudWatch dimensions
