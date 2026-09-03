# AWS Multi-Region Disaster Recovery with Terraform

A practical Disaster Recovery (DR) solution designed to protect application infrastructure and data from failures, outages, accidental deletion, and regional disasters.

The project demonstrates how to design, implement, monitor, and test a reliable disaster recovery strategy using AWS cloud services, Infrastructure as Code, automation, and monitoring.

## 🏗️ Architecture

```
                         ┌──────────────────────┐
                         │       Route 53       │
                         │ Health Check / DNS   │
                         │   Failover Routing   │
                         └──────────┬───────────┘
                                    │
                         ┌──────────▼───────────┐
                         │    PRIMARY REGION    │
                         │      ap-south-1      │
                         │                      │
                         │ ┌──────────────────┐ │
                         │ │ EC2 Application  │ │
                         │ └────────┬─────────┘ │
                         │          │           │
                         │      ┌───▼───┐       │
                         │      │  EBS  │       │
                         │      └───┬───┘       │
                         │          │           │
                         │      Snapshots       │
                         │                      │
                         │ ┌──────────────────┐ │
                         │ │       RDS        │ │
                         │ └────────┬─────────┘ │
                         │          │           │
                         │   Automated Backup   │
                         └──────────┬───────────┘
                                    │
                         Cross-Region Replication
                                    │
                         ┌──────────▼───────────┐
                         │      DR REGION       │
                         │      ap-south-2      │
                         │                      │
                         │ ┌──────────────────┐ │
                         │ │   S3 Backup      │ │
                         │ │     Bucket       │ │
                         │ └──────────────────┘ │
                         │                      │
                         │ ┌──────────────────┐ │
                         │ │ EBS Snapshots    │ │
                         │ └──────────────────┘ │
                         │                      │
                         │ ┌──────────────────┐ │
                         │ │ RDS Replica /    │ │
                         │ │ Snapshot         │ │
                         │ └──────────────────┘ │
                         │                      │
                         │ ┌──────────────────┐ │
                         │ │    Terraform     │ │
                         │ │ Recovery / IaC   │ │
                         │ └────────┬─────────┘ │
                         │          │           │
                         │      ┌───▼───────┐   │
                         │      │ EC2 / RDS │   │
                         │      │ Networking│   │
                         │      └───────────┘   │
                         └──────────┬───────────┘
                                    │
                                  Failover
                                    │
                         ┌──────────▼───────────┐
                         │       Route 53       │
                         │      DR Target       │
                         └──────────────────────┘


                ┌─────────────────────────────────────────┐
                │              CloudWatch                 │
                │        Metrics / Alarms / Logs          │
                └───────────────────┬─────────────────────┘
                                    │
                               ┌────▼─────┐
                               │  Lambda  │
                               │ Backup / │
                               │ Recovery │
                               └──────────┘

- Multi-AZ VPCs in primary and DR regions
- ALB + Auto Scaling application tier
- RDS MySQL in primary and cross-region read replica in DR
- S3 versioning + cross-region replication
- AWS Backup plan for EBS
- Route 53 failover records and health check
- CloudWatch alarms
- Lambda helper for DR Auto Scaling activation

```

🎯 Recommended RPO/RTO

| Metric                      | Target                                                    |
| --------------------------- | --------------------------------------------------------- |
| **RPO**                     | ≤ 15 minutes for database/application data                |
| **RTO**                     | ≤ 30–60 minutes                                           |
| **EBS Snapshot Frequency**  | Every 1 hour                                              |
| **RDS Backup**              | Automated daily backups + continuous/PITR where supported |
| **S3 Backup**               | Versioning + Cross-Region Replication                     |
| **Infrastructure Recovery** | Terraform                                                 |
| **DNS Failover**            | Route 53 Health Checks + Failover Routing                 |
| **Monitoring**              | CloudWatch Metrics, Alarms & Logs                         |
| **Automation**              | AWS Lambda                                                |

### What this means

RPO (Recovery Point Objective) ≤ 15 minutes

- In a disaster, you aim to lose no more than 15 minutes of data.

RTO (Recovery Time Objective) ≤ 30–60 minutes

- The application should be restored and accessible within 30–60 minutes after a major failure.

Primary region: `ap-south-1` (Mumbai)
DR region: `us-east-1` (N. Virginia) — change `dr_region` if desired.

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

📈 Recovery Validation

After recovery, verify:

```
☑ Application is accessible
☑ Load balancer is healthy
☑ EC2 instances are healthy
☑ Database is available
☑ Data integrity is confirmed
☑ DNS is resolving correctly
☑ Monitoring is operational
☑ Logs are available
☑ No critical alarms remain
```

💰 Cost Optimization

The DR environment should balance recovery requirements with cost.

Possible approaches:

Use smaller instances in DR
Use automated scaling
Use S3 lifecycle policies
Retain only required backups
Use managed AWS services
Shut down non-critical DR resources when appropriate
Monitor backup storage costs

## 👨‍💻 Author

**Ratnesh Vansh Saxena**

DevOps / Cloud Engineering

Skills Demonstrated

AWS Terraform Docker Linux Git CI/CD Monitoring Disaster Recovery

## ⭐ Conclusion

This project demonstrates a practical approach to building a resilient cloud infrastructure capable of recovering from infrastructure, application, database, and regional failures.

The primary objective is to minimize downtime and data loss while maintaining a clear, repeatable, and testable recovery process.
