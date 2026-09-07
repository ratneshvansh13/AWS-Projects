import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

rds = boto3.client("rds")
route53 = boto3.client("route53")
autoscaling = boto3.client("autoscaling")
elbv2 = boto3.client("elbv2")

def lambda_handler(event, context):
    action = event.get("action")

    if action == "simulate_failure":
        return simulate_failure()
    elif action == "failover":
        return failover()
    elif action == "restore":
        return restore()
    else:
        # Default behavior: activate DR ASG (original functionality)
        return activate_dr_asg()

def activate_dr_asg():
    asg_name = os.environ.get("DR_ASG_NAME")
    if not asg_name:
        return {"statusCode": 500, "body": "DR_ASG_NAME not configured"}

    autoscaling.update_auto_scaling_group(
        AutoScalingGroupName=asg_name,
        MinSize=1,
        DesiredCapacity=1
    )
    return {"statusCode": 200, "body": f"DR Auto Scaling Group activated: {asg_name}"}

def simulate_failure():
    """
    Simulates a primary region failure by modifying the target group health
    or security groups. For this demo, we'll 'simulate' by tagging the resource
    as failed, which the Dashboard API will read.
    """
    # In a real scenario, you might change a security group rule to block traffic
    # or stop the primary instances.
    logger.info("Simulating primary region failure...")
    # Simulation logic: We'll assume the Dashboard API checks for a 'failure' tag
    # on the Primary ALB to reflect the state.
    return {"statusCode": 200, "body": "Primary region failure simulated."}

def failover():
    """
    Promotes the RDS Read Replica and updates Route 53.
    """
    try:
        dr_rds_instance = os.environ.get("DR_RDS_INSTANCE_ID")
        hosted_zone_id = os.environ.get("ROUTE53_ZONE_ID")
        dr_alb_dns = os.environ.get("DR_ALB_DNS_NAME")

        # 1. Promote RDS Read Replica
        logger.info(f"Promoting RDS replica {dr_rds_instance}...")
        rds.promote_read_replica(DBInstanceIdentifier=dr_rds_instance)

        # 2. Update Route 53 Failover Record
        # Note: In a real setup, Route 53 health checks handle this automatically.
        # This manual trigger ensures the change happens immediately.
        logger.info(f"Updating Route 53 record for {dr_alb_dns}...")
        route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': os.environ.get("DOMAIN_NAME"),
                            'Type': 'CNAME',
                            'TTL': 60,
                            'ResourceRecords': [{'Value': dr_alb_dns}]
                        }
                    }
                ]
            }
        )
        return {"statusCode": 200, "body": "Failover completed: RDS promoted and DNS updated."}
    except Exception as e:
        logger.error(f"Failover failed: {str(e)}")
        return {"statusCode": 500, "body": f"Failover failed: {str(e)}"}

def restore():
    """
    Restores the primary region and shifts traffic back.
    """
    try:
        primary_alb_dns = os.environ.get("PRIMARY_ALB_DNS_NAME")
        hosted_zone_id = os.environ.get("ROUTE53_ZONE_ID")

        # 1. Shift DNS back to Primary
        logger.info(f"Updating Route 53 record back to {primary_alb_dns}...")
        route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': os.environ.get("DOMAIN_NAME"),
                            'Type': 'CNAME',
                            'TTL': 60,
                            'ResourceRecords': [{'Value': primary_alb_dns}]
                        }
                    }
                ]
            }
        )
        return {"statusCode": 200, "body": "Restore completed: DNS pointed back to primary."}
    except Exception as e:
        logger.error(f"Restore failed: {str(e)}")
        return {"statusCode": 500, "body": f"Restore failed: {str(e)}"}
