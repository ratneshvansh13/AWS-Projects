terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}

provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project     = "AWS-Disaster-Recovery"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Region      = "Primary"
    }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Project     = "AWS-Disaster-Recovery"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Region      = "DR"
    }
  }
}

provider "aws" {
  alias  = "route53"
  region = var.primary_region
}

provider "aws" {
  alias  = "lambda_dr"
  region = var.dr_region
}
