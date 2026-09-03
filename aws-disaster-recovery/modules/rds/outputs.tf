output "db_arn" {
  value = aws_db_instance.this.arn
}

output "db_identifier" {
  value = aws_db_instance.this.identifier
}

output "db_endpoint" {
  value = aws_db_instance.this.address
}
