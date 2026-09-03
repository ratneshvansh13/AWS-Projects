terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.dr]
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "primary_unhealthy_hosts" {
  alarm_name          = "dr-primary-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Primary ALB has unhealthy targets."

  dimensions = {
    LoadBalancer = regex("loadbalancer/(.+)", var.primary_alb_arn)[0]
  }
}

resource "aws_cloudwatch_metric_alarm" "dr_unhealthy_hosts" {
  provider = aws.dr

  alarm_name          = "dr-secondary-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "DR ALB has unhealthy targets."

  dimensions = {
    LoadBalancer = regex("loadbalancer/(.+)", var.dr_alb_arn)[0]
  }
}
