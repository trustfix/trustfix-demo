# =============================================================================
# TrustFix Demo Environment - Variables
# =============================================================================

variable "github_org" {
  description = "Your GitHub organization or username where the demo repo is hosted"
  type        = string

  validation {
    condition     = length(var.github_org) > 0
    error_message = "github_org must not be empty"
  }
}

variable "github_repo" {
  description = "Name of the demo repository (default: trustfix-demo)"
  type        = string
  default     = "trustfix-demo"
}

variable "aws_region" {
  description = "AWS region for deploying demo resources"
  type        = string
  default     = "us-east-1"
}

variable "enable_bedrock" {
  description = "Enable Bedrock agent resources (costs money, disabled by default)"
  type        = bool
  default     = false
}

variable "enable_lambda" {
  description = "Enable Lambda function resources (minimal cost)"
  type        = bool
  default     = true
}

variable "trustfix_aws_account_id" {
  description = "TrustFix platform AWS account ID for scanner role trust. Update with real TrustFix account ID when connecting."
  type        = string
  default     = ""

  validation {
    condition     = var.trustfix_aws_account_id == "" || can(regex("^[0-9]{12}$", var.trustfix_aws_account_id))
    error_message = "Must be empty or a valid 12-digit AWS account ID."
  }
}
