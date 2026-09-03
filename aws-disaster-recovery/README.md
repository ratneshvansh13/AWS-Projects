# AWS Multi-Region Disaster Recovery with Terraform

Primary region: `ap-south-1` (Mumbai)
DR region: `us-east-1` (N. Virginia) — change `dr_region` if desired.

## Architecture

- Multi-AZ VPCs in primary and DR regions
- ALB + Auto Scaling application tier
- RDS MySQL in primary and cross-region read replica in DR
- S3 versioning + cross-region replication
- AWS Backup plan for EBS
- Route 53 failover records and health check
- CloudWatch alarms
- Lambda helper for DR Auto Scaling activation

## Before you apply

1. Configure AWS credentials (`aws configure` or environment variables).
2. Set `domain_name` and `route53_zone_id` in `terraform.tfvars` if you want Route 53 records.
3. Set `enable_route53 = false` if you do not have a hosted zone.
4. Review RDS/EC2/S3/NAT costs. This project creates billable resources.
5. For production, put Terraform state in an encrypted S3 backend with DynamoDB/S3 locking and use a CI/CD role.

## Commands

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

After apply:

```bash
terraform output primary_alb_dns_name
terraform output dr_alb_dns_name
```

To remove everything:

```bash
terraform destroy
```

## DR test

1. Confirm the primary ALB is healthy.
2. Open the primary ALB DNS name.
3. Simulate primary failure by stopping/terminating the primary ASG instances or blocking the health endpoint.
4. Route 53 should move traffic to the secondary record after health-check evaluation.
5. Validate the DR ALB and DR database replica.
6. Restore the primary side and switch DNS back deliberately.

> This is a learning/portfolio implementation. Validate RPO/RTO, database promotion, secrets, encryption keys, DNS TTLs, and operational runbooks before using it for production.
