variable "primary_region" {
  type    = string
  default = "ap-south-1"
}

variable "dr_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dr"
}

variable "primary_vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "dr_vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "primary_public_subnet_az1_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "primary_public_subnet_az2_cidr" {
  type    = string
  default = "10.10.2.0/24"
}

variable "primary_private_subnet_az1_cidr" {
  type    = string
  default = "10.10.11.0/24"
}

variable "primary_private_subnet_az2_cidr" {
  type    = string
  default = "10.10.12.0/24"
}

variable "dr_public_subnet_az1_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "dr_public_subnet_az2_cidr" {
  type    = string
  default = "10.20.2.0/24"
}

variable "dr_private_subnet_az1_cidr" {
  type    = string
  default = "10.20.11.0/24"
}

variable "dr_private_subnet_az2_cidr" {
  type    = string
  default = "10.20.12.0/24"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "primary_asg_min" {
  type    = number
  default = 1
}

variable "primary_asg_desired" {
  type    = number
  default = 1
}

variable "primary_asg_max" {
  type    = number
  default = 2
}

variable "dr_asg_min" {
  type    = number
  default = 1
}

variable "dr_asg_desired" {
  type    = number
  default = 1
}

variable "dr_asg_max" {
  type    = number
  default = 2
}

variable "db_name" {
  type    = string
  default = "drapp"
}

variable "db_username" {
  type    = string
  default = "dradmin"
}

variable "db_password" {
  type      = string
  default   = "DefaultPassword123!"
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_engine_version" {
  type    = string
  default = "8.0"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_backup_retention" {
  type    = number
  default = 7
}

variable "domain_name" {
  description = "DNS name used for the application, e.g. app.example.com"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Existing Route 53 hosted zone ID. Leave empty to disable DNS records."
  type        = string
  default     = ""
}

variable "enable_route53" {
  type    = bool
  default = false
}

variable "enable_s3_replication" {
  type    = bool
  default = true
}

variable "enable_rds_dr" {
  description = "Create the cross-region RDS read replica. Disable to reduce cost during initial testing."
  type        = bool
  default     = true
}
