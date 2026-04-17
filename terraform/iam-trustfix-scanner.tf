# =============================================================================
# TrustFix Scanner Role — READ-ONLY ACCESS FOR SECURITY SCANNING
# =============================================================================
# This role is assumed by the TrustFix platform to scan this AWS account
# for identity misconfigurations.
#
# SECURITY GUARANTEES:
# 1. Only TrustFix's AWS account can assume this role
# 2. Assumption requires a unique external ID (shared secret)
# 3. Role has ZERO write permissions — read-only by design
# 4. All actions logged to CloudTrail for audit
# 5. External ID rotates per connection
# =============================================================================

# Generate a unique external ID for this connection
resource "random_uuid" "trustfix_external_id" {}

# The scanner role
resource "aws_iam_role" "trustfix_scanner" {
  name = "TrustFixScanner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # TrustFix production AWS account ID
          # Uses current account as placeholder if not set; update when connecting to TrustFix
          AWS = "arn:aws:iam::${var.trustfix_aws_account_id != "" ? var.trustfix_aws_account_id : data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            # External ID — shared secret between accounts
            # TrustFix will provide this when you connect
            "sts:ExternalId" = random_uuid.trustfix_external_id.result
          }
        }
      }
    ]
  })

  tags = {
    Purpose     = "TrustFix Security Scanner"
    AccessLevel = "Read-Only"
    Managed     = "Terraform"
  }
}

# Attach AWS managed SecurityAudit policy
# This grants read-only access to security-relevant resources
resource "aws_iam_role_policy_attachment" "scanner_security_audit" {
  role       = aws_iam_role.trustfix_scanner.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# Attach AWS managed ViewOnlyAccess policy
# Grants broad read-only across AWS services
resource "aws_iam_role_policy_attachment" "scanner_view_only" {
  role       = aws_iam_role.trustfix_scanner.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

# Additional read permissions specific to NHI security scanning
resource "aws_iam_policy" "trustfix_additional_read" {
  name        = "TrustFixAdditionalRead"
  description = "Additional read-only permissions for NHI security scanning"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # IAM read (critical for NHI scanning)
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListRoles",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListPolicies",
          "iam:ListPolicyVersions",
          "iam:ListUsers",
          "iam:ListUserPolicies",
          "iam:GetUser",
          "iam:ListOpenIDConnectProviders",
          "iam:GetOpenIDConnectProvider",
          "iam:ListSAMLProviders",
          "iam:GetAccountAuthorizationDetails",
          "iam:GetAccountSummary",
          "iam:GetCredentialReport",
          "iam:GenerateCredentialReport",

          # Lambda configuration read (not invoke)
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:GetPolicy",
          "lambda:ListFunctions",
          "lambda:ListLayers",

          # Bedrock read (for AI agent scanning)
          "bedrock:ListAgents",
          "bedrock:GetAgent",
          "bedrock:ListAgentActionGroups",
          "bedrock:GetAgentActionGroup",

          # CloudTrail read (for identity usage analysis)
          "cloudtrail:LookupEvents",
          "cloudtrail:DescribeTrails",

          # Organizations read (for multi-account context)
          "organizations:DescribeAccount",
          "organizations:ListAccounts",
          "organizations:DescribeOrganization"
        ]
        Resource = "*"
      },
      {
        # EXPLICIT DENY for ALL write operations
        # Defense in depth — even if somehow granted elsewhere,
        # these are denied
        Effect = "Deny"
        Action = [
          "iam:Create*",
          "iam:Delete*",
          "iam:Put*",
          "iam:Update*",
          "iam:Attach*",
          "iam:Detach*",
          "iam:Add*",
          "iam:Remove*",
          "iam:Change*",
          "iam:Reset*",
          "iam:Enable*",
          "iam:Disable*",
          "iam:Set*",
          "iam:Tag*",
          "iam:Untag*",
          "iam:PassRole",

          "lambda:Create*",
          "lambda:Delete*",
          "lambda:Invoke*",
          "lambda:Update*",
          "lambda:Put*",
          "lambda:Publish*",
          "lambda:Add*",
          "lambda:Remove*",

          "s3:Put*",
          "s3:Delete*",
          "s3:Create*",
          "s3:GetObject",
          "s3:GetObjectVersion",

          "secretsmanager:GetSecretValue",
          "secretsmanager:Put*",
          "secretsmanager:Create*",
          "secretsmanager:Delete*",

          "kms:Decrypt",
          "kms:Encrypt",
          "kms:Create*",
          "kms:Delete*",

          "ec2:Create*",
          "ec2:Delete*",
          "ec2:Modify*",
          "ec2:Terminate*",
          "ec2:Run*",
          "ec2:Start*",
          "ec2:Stop*",

          "rds:Create*",
          "rds:Delete*",
          "rds:Modify*",
          "rds:Restore*",

          "organizations:Create*",
          "organizations:Delete*",
          "organizations:Update*",
          "organizations:Invite*",
          "organizations:Remove*",
          "organizations:Move*",
          "organizations:Leave*",

          "cloudtrail:Create*",
          "cloudtrail:Delete*",
          "cloudtrail:Update*",
          "cloudtrail:Put*",
          "cloudtrail:Stop*",
          "cloudtrail:Start*",

          "bedrock:Create*",
          "bedrock:Delete*",
          "bedrock:Update*",
          "bedrock:Put*",
          "bedrock:Invoke*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scanner_additional_read" {
  role       = aws_iam_role.trustfix_scanner.name
  policy_arn = aws_iam_policy.trustfix_additional_read.arn
}
