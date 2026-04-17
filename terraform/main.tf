# =============================================================================
# TrustFix Demo Environment - Main Terraform Configuration
# =============================================================================
# WARNING: This infrastructure is INTENTIONALLY VULNERABLE for demonstration.
# Deploy only to sandbox/demo AWS accounts. Never use in production.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "TrustFix-Demo"
      Purpose     = "TrustFix Demo Environment"
      Warning     = "INTENTIONALLY VULNERABLE - Do Not Use In Production"
      ManagedBy   = "Terraform"
      Repository  = "trustfix/trustfix-demo"
      Environment = "demo"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
