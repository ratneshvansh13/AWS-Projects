module "primary_vpc" {
  source = "./modules/vpc"

  vpc_name = "dr-primary-vpc"
  vpc_cidr = var.primary_vpc_cidr

  public_subnet_az1_cidr  = var.primary_public_subnet_az1_cidr
  public_subnet_az2_cidr  = var.primary_public_subnet_az2_cidr
  private_subnet_az1_cidr = var.primary_private_subnet_az1_cidr
  private_subnet_az2_cidr = var.primary_private_subnet_az2_cidr
}

module "dr_vpc" {
  source = "./modules/vpc"

  providers = {
    aws = aws.dr
  }

  vpc_name = "dr-secondary-vpc"
  vpc_cidr = var.dr_vpc_cidr

  public_subnet_az1_cidr  = var.dr_public_subnet_az1_cidr
  public_subnet_az2_cidr  = var.dr_public_subnet_az2_cidr
  private_subnet_az1_cidr = var.dr_private_subnet_az1_cidr
  private_subnet_az2_cidr = var.dr_private_subnet_az2_cidr
}

module "primary_security" {
  source = "./modules/security"

  vpc_id       = module.primary_vpc.vpc_id
  vpc_name     = "primary"
  app_port     = 8080
  db_port      = 3306
  allowed_cidr = var.primary_vpc_cidr
}

module "dr_security" {
  source = "./modules/security"

  providers = {
    aws = aws.dr
  }

  vpc_id       = module.dr_vpc.vpc_id
  vpc_name     = "dr"
  app_port     = 8080
  db_port      = 3306
  allowed_cidr = var.dr_vpc_cidr
}

module "primary_alb" {
  source = "./modules/alb"

  vpc_id         = module.primary_vpc.vpc_id
  public_subnets = module.primary_vpc.public_subnet_ids
  security_group = module.primary_security.alb_security_group_id
  target_port    = 8080
  name           = "primary"
}

module "dr_alb" {
  source = "./modules/alb"

  providers = {
    aws = aws.dr
  }

  vpc_id         = module.dr_vpc.vpc_id
  public_subnets = module.dr_vpc.public_subnet_ids
  security_group = module.dr_security.dr_alb_security_group_id
  target_port    = 8080
  name           = "dr"
}

module "primary_compute" {
  source = "./modules/compute"

  name              = "primary"
  vpc_id            = module.primary_vpc.vpc_id
  private_subnets   = module.primary_vpc.private_subnet_ids
  instance_type     = var.instance_type
  target_group_arn  = module.primary_alb.target_group_arn
  security_group_id = module.primary_security.app_security_group_id
  min_size          = var.primary_asg_min
  desired_capacity  = var.primary_asg_desired
  max_size          = var.primary_asg_max
  app_port          = 8080
}

module "dr_compute" {
  source = "./modules/compute"

  providers = {
    aws = aws.dr
  }

  name              = "dr"
  vpc_id            = module.dr_vpc.vpc_id
  private_subnets   = module.dr_vpc.private_subnet_ids
  instance_type     = var.instance_type
  target_group_arn  = module.dr_alb.target_group_arn
  security_group_id = module.dr_security.app_security_group_id
  min_size          = var.dr_asg_min
  desired_capacity  = var.dr_asg_desired
  max_size          = var.dr_asg_max
  app_port          = 8080
}

module "primary_rds" {
  source = "./modules/rds"

  name              = "primary"
  vpc_id            = module.primary_vpc.vpc_id
  private_subnets   = module.primary_vpc.private_subnet_ids
  security_group_id = module.primary_security.db_security_group_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  instance_class    = var.db_instance_class
  engine_version    = var.db_engine_version
  allocated_storage = var.db_allocated_storage
  backup_retention  = var.db_backup_retention
}

module "dr_rds" {
  source = "./modules/rds_replica"

  providers = {
    aws = aws.dr
  }

  count = var.enable_rds_dr ? 1 : 0

  identifier        = "dr-replica"
  source_db_arn     = module.primary_rds.db_arn
  private_subnets   = module.dr_vpc.private_subnet_ids
  security_group_id = module.dr_security.db_security_group_id
  instance_class    = var.db_instance_class
  engine_version    = var.db_engine_version
  kms_key_id        = aws_kms_key.dr_rds.arn
}

module "s3" {
  source = "./modules/s3"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  bucket_prefix      = "dr-primary"
  enable_replication = var.enable_s3_replication
  dr_region          = var.dr_region
}

module "backup" {
  source = "./modules/backup"

  name = "dr-backup"
}

module "route53" {
  source = "./modules/route53"

  count = var.enable_route53 && var.route53_zone_id != "" && var.domain_name != "" ? 1 : 0

  zone_id              = var.route53_zone_id
  domain_name          = var.domain_name
  primary_alb_dns_name = module.primary_alb.alb_dns_name
  dr_alb_dns_name      = module.dr_alb.alb_dns_name
  primary_alb_zone_id  = module.primary_alb.alb_zone_id
  dr_alb_zone_id       = module.dr_alb.alb_zone_id
}

module "monitoring" {
  source = "./modules/monitoring"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  primary_asg_name = module.primary_compute.asg_name
  dr_asg_name      = module.dr_compute.asg_name
  primary_alb_arn  = module.primary_alb.alb_arn
  dr_alb_arn       = module.dr_alb.alb_arn
}

module "dr_lambda" {
  source = "./modules/lambda"

  providers = {
    aws = aws.lambda_dr
  }

  dr_asg_name = module.dr_compute.asg_name
}

resource "aws_kms_key" "dr_rds" {
  provider = aws.dr

  description = "KMS key for DR RDS encryption"

  deletion_window_in_days = 7

  tags = {
    Name = "dr-rds-kms"
  }
}

resource "aws_kms_alias" "dr_rds" {
  provider = aws.dr

  name          = "alias/dr-rds"
  target_key_id = aws_kms_key.dr_rds.key_id
}
