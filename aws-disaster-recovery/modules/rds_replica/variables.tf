variable "identifier" { type = string }
variable "source_db_arn" { type = string }
variable "private_subnets" { type = list(string) }
variable "security_group_id" { type = string }
variable "instance_class" { type = string }
variable "engine_version" { type = string }
variable "kms_key_id" { type = string }
