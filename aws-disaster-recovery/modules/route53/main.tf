terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3

  tags = {
    Name = "dr-primary-health-check"
  }
}

resource "aws_route53_record" "primary" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "primary"

  alias {
    name                   = var.primary_alb_dns_name
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "secondary" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "secondary"

  alias {
    name                   = var.dr_alb_dns_name
    zone_id                = var.dr_alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }
}
