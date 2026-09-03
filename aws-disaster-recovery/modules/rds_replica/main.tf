terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "dr-replica-db-subnet-group"
  subnet_ids = var.private_subnets
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  replicate_source_db = var.source_db_arn

  engine_version = var.engine_version

  instance_class = var.instance_class

  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = [var.security_group_id]

  storage_encrypted = true

  kms_key_id = var.kms_key_id

  publicly_accessible = false

  skip_final_snapshot = true

  tags = {
    Name = var.identifier
  }
}
