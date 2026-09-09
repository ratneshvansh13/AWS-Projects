output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_arn" {
  value = aws_db_instance.this.arn
}
