primary_region = "ap-south-1"
dr_region      = "us-east-1"
environment    = "dr"

instance_type = "t3.micro"

primary_asg_min     = 1
primary_asg_desired = 1
primary_asg_max     = 2

dr_asg_min     = 1
dr_asg_desired = 1
dr_asg_max     = 2

db_name              = "drapp"
db_username          = "dradmin"
db_instance_class    = "db.t3.micro"
db_engine_version    = "8.0"
db_allocated_storage = 20
db_backup_retention  = 7

enable_s3_replication = true
enable_rds_dr         = true

# Set these only if you own an existing Route 53 hosted zone.
enable_route53  = false
route53_zone_id = ""
domain_name     = "app.example.com"
