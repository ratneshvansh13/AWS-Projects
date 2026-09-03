import os
import boto3

autoscaling = boto3.client("autoscaling")

def lambda_handler(event, context):
    asg_name = os.environ["DR_ASG_NAME"]

    autoscaling.update_auto_scaling_group(
        AutoScalingGroupName=asg_name,
        MinSize=1,
        DesiredCapacity=1
    )

    return {
        "statusCode": 200,
        "body": f"DR Auto Scaling Group activated: {asg_name}"
    }
