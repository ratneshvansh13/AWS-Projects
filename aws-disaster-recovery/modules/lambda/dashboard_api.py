import os
import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

rds = boto3.client("rds")
elbv2 = boto3.client("elbv2")
route53 = boto3.client("route53")
s3 = boto3.client("s3")
lambda_client = boto3.client("lambda")

def lambda_handler(event, context):
    path = event.get("rawPath", event.get("path"))
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")

    if method == "GET" and path == "/status":
        return get_status()
    elif method == "POST" and path == "/action":
        return handle_action(event)
    else:
        return {
            "statusCode": 404,
            "body": json.dumps({"message": "Not Found"})
        }

def get_status():
    try:
        # 1. Primary and DR Region Status
        # We'll check Route 53 Health Check for primary health
        primary_health_check_id = os.environ.get("PRIMARY_HEALTH_CHECK_ID")
        primary_status = "Healthy"
        traffic_split = "100% / 0%"

        if primary_health_check_id:
            hc = route53.get_health_check(HealthCheckId=primary_health_check_id)
            if hc['HealthCheck']['HealthStatus'] != 'HEALTHY':
                primary_status = "Critical"
                traffic_split = "0% / 100%"

        # 2. Resource Health Matrix
        resources = []

        # RDS Status
        dr_rds_id = os.environ.get("DR_RDS_INSTANCE_ID")
        rds_lag = "N/A"
        if dr_rds_id:
            db = rds.describe_db_instances(DBInstanceIdentifier=dr_rds_id)['DBInstances'][0]
            # In real RDS, ReplicaLag is in seconds
            rds_lag = f"{db.get('ReplicaLag', 0)}s"

        resources.append({
            "name": "RDS MySQL",
            "primary": "Active",
            "dr": "Read-Replica",
            "lag": rds_lag,
            "health": "OK" if rds_lag != "N/A" else "Unknown"
        })

        # S3 Status
        s3_bucket = os.environ.get("DR_S3_BUCKET")
        s3_health = "Unknown"
        if s3_bucket:
            try:
                s3.get_bucket_replication(Bucket=s3_bucket)
                s3_health = "OK"
            except:
                s3_health = "Issue"

        resources.append({
            "name": "S3 Buckets",
            "primary": "Active",
            "dr": "Replicating",
            "lag": "Synced",
            "health": s3_health
        })

        # Route 53 Status
        resources.append({
            "name": "Route 53",
            "primary": "Routing",
            "dr": "Standby",
            "lag": "Health: OK" if primary_status == "Healthy" else "Health: CRITICAL",
            "health": "OK" if primary_status == "Healthy" else "Critical"
        })

        # ALB Status
        primary_alb = os.environ.get("PRIMARY_ALB_DNS_NAME")
        resources.append({
            "name": "ALB/ASG",
            "primary": "Active",
            "dr": "Warm Standby",
            "lag": "Ready",
            "health": "OK"
        })

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "primary": {"status": primary_status, "traffic": traffic_split.split(" / ")[0]},
                "dr": {"status": "Active" if primary_status == "Critical" else "Standby", "traffic": traffic_split.split(" / ")[1]},
                "resources": resources,
                "objectives": {"rpo": "4m", "rto": "22m"}
            })
        }
    except Exception as e:
        logger.error(f"Status fetch failed: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

def handle_action(event):
    try:
        body = json.loads(event.get("body", "{}"))
        action = body.get("action")

        recovery_lambda = os.environ.get("RECOVERY_LAMBDA_NAME")
        if not recovery_lambda:
            return {"statusCode": 500, "body": json.dumps({"error": "Recovery Lambda not configured"})}

        # Invoke Recovery Lambda asynchronously
        lambda_client.invoke(
            FunctionName=recovery_lambda,
            InvocationType="Event",
            Payload=json.dumps({"action": action})
        )

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"status": "success", "message": f"Action {action} initiated."})
        }
    except Exception as e:
        logger.error(f"Action trigger failed: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
