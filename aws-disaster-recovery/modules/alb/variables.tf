variable "vpc_id" { type = string }
variable "public_subnets" { type = list(string) }
variable "security_group" { type = string }
variable "target_port" { type = number }
variable "name" { type = string }
