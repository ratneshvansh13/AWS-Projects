output "primary_region" {
  value = var.primary_region
}

output "dr_region" {
  value = var.dr_region
}

output "primary_vpc_id" {
  value = module.primary_vpc.vpc_id
}

output "dr_vpc_id" {
  value = module.dr_vpc.vpc_id
}

output "primary_alb_dns_name" {
  value = module.primary_alb.alb_dns_name
}

output "dr_alb_dns_name" {
  value = module.dr_alb.alb_dns_name
}

output "primary_rds_endpoint" {
  value = module.primary_rds.db_endpoint
}

output "dr_rds_endpoint" {
  value = var.enable_rds_dr ? module.dr_rds[0].db_endpoint : null
}

output "primary_s3_bucket" {
  value = module.s3.primary_bucket_name
}

output "dr_s3_bucket" {
  value = module.s3.dr_bucket_name
}

output "route53_enabled" {
  value = var.enable_route53 && var.route53_zone_id != "" && var.domain_name != ""
}
