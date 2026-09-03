output "primary_bucket_name" {
  value = aws_s3_bucket.primary.bucket
}

output "dr_bucket_name" {
  value = aws_s3_bucket.dr.bucket
}
