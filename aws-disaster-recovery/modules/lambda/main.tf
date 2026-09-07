terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

# --- Archives ---

data "archive_file" "recovery_lambda" {
  type        = "zip"
  source_file = "${path.module}/recovery.py"
  output_path = "${path.module}/recovery.zip"
}

data "archive_file" "dashboard_api_lambda" {
  type        = "zip"
  source_file = "${path.module}/dashboard_api.py"
  output_path = "${path.module}/dashboard_api.zip"
}

# --- IAM Role for Recovery Lambda ---

resource "aws_iam_role" "recovery_role" {
  name = "dr-recovery-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "recovery_policy" {
  role = aws_iam_role.recovery_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "rds:PromoteReadReplica",
          "route53:ChangeResourceRecordSets",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- IAM Role for Dashboard API Lambda ---

resource "aws_iam_role" "api_role" {
  name = "dr-dashboard-api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "api_policy" {
  role = aws_iam_role.api_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetHealth",
          "route53:GetHealthCheck",
          "s3:GetBucketReplication",
          "lambda:InvokeFunction",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- Lambda Functions ---

resource "aws_lambda_function" "recovery" {
  function_name = "dr-recovery-helper"
  role          = aws_iam_role.recovery_role.arn
  handler       = "recovery.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.recovery_lambda.output_path
  source_code_hash = data.archive_file.recovery_lambda.output_base64sha256

  environment {
    variables = {
      DR_ASG_NAME         = var.dr_asg_name
      DR_RDS_INSTANCE_ID  = var.dr_rds_instance_id
      ROUTE53_ZONE_ID     = var.route53_zone_id
      DOMAIN_NAME         = var.domain_name
      DR_ALB_DNS_NAME     = var.dr_alb_dns_name
      PRIMARY_ALB_DNS_NAME = var.primary_alb_dns_name
    }
  }
}

resource "aws_lambda_function" "api" {
  function_name = "dr-dashboard-api"
  role          = aws_iam_role.api_role.arn
  handler       = "dashboard_api.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.dashboard_api_lambda.output_path
  source_code_hash = data.archive_file.dashboard_api_lambda.output_base64sha256

  environment {
    variables = {
      RECOVERY_LAMBDA_NAME     = aws_lambda_function.recovery.function_name
      PRIMARY_ALB_DNS_NAME     = var.primary_alb_dns_name
      DR_ALB_DNS_NAME          = var.dr_alb_dns_name
      DR_RDS_INSTANCE_ID       = var.dr_rds_instance_id
      DR_S3_BUCKET             = var.dr_s3_bucket
      PRIMARY_HEALTH_CHECK_ID  = var.primary_health_check_id
    }
  }
}

# --- API Gateway (HTTP API) ---

resource "aws_apigatewayv2_api" "dashboard_api" {
  name          = "dr-dashboard-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_integration" "api_integration" {
  api_id           = aws_apigatewayv2_api.dashboard_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.api.invoke_arn
}

resource "aws_apigatewayv2_route" "status_route" {
  api_id    = aws_apigatewayv2_api.dashboard_api.id
  route_key = "GET /status"
  target    = "integrations/${aws_apigatewayv2_integration.api_integration.id}"
}

resource "aws_apigatewayv2_route" "action_route" {
  api_id    = aws_apigatewayv2_api.dashboard_api.id
  route_key = "POST /action"
  target    = "integrations/${aws_apigatewayv2_integration.api_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.dashboard_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dashboard_api.execution_arn}/*/*"
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.dashboard_api.api_endpoint
}
