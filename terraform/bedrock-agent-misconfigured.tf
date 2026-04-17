# =============================================================================
# INTENTIONALLY VULNERABLE - Bedrock Agent Misconfigurations
# =============================================================================
# These resources demonstrate AI/ML agent security issues that TrustFix
# should detect. Only created if enable_bedrock=true (costs money).
# =============================================================================

# -----------------------------------------------------------------------------
# Role: TrustFixDemo-BedrockAgentOverprivileged
# INTENTIONAL VULNERABILITY: AI_AGENT_OVERPRIVILEGED_ROLE
# -----------------------------------------------------------------------------
# A Bedrock agent role with excessive permissions (bedrock:*, s3:*).
# AI agents should have minimal, scoped permissions.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "bedrock_agent_overprivileged" {
  count = var.enable_bedrock ? 1 : 0
  name  = "TrustFixDemo-BedrockAgentOverprivileged"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Vulnerability   = "AI_AGENT_OVERPRIVILEGED_ROLE"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "Critical"
    ExpectedFinding = "Bedrock agent role has bedrock:* and s3:* permissions"
  }
}

resource "aws_iam_role_policy" "bedrock_agent_overprivileged_policy" {
  count = var.enable_bedrock ? 1 : 0
  name  = "OverprivilegedBedrockPolicy"
  role  = aws_iam_role.bedrock_agent_overprivileged[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # VULNERABILITY: Wildcard permissions on Bedrock
        Action = [
          "bedrock:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        # VULNERABILITY: Wildcard S3 access
        Action = [
          "s3:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        # VULNERABILITY: Can invoke any Lambda
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Role: TrustFixDemo-BedrockAgentMissingScope
# INTENTIONAL VULNERABILITY: AI_AGENT_MISSING_SCOPE_CONDITION
# -----------------------------------------------------------------------------
# A Bedrock agent role without proper scope conditions. The role can
# be assumed by any Bedrock operation without restrictions.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "bedrock_agent_missing_scope" {
  count = var.enable_bedrock ? 1 : 0
  name  = "TrustFixDemo-BedrockAgentMissingScope"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        # VULNERABILITY: No conditions restricting which Bedrock
        # agents or operations can assume this role
        # Missing conditions like:
        # - aws:SourceAccount
        # - aws:SourceArn (specific agent ARN)
      }
    ]
  })

  tags = {
    Vulnerability   = "AI_AGENT_MISSING_SCOPE_CONDITION"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "High"
    ExpectedFinding = "Bedrock agent role has no scope restrictions in trust policy"
  }
}

resource "aws_iam_role_policy" "bedrock_agent_missing_scope_policy" {
  count = var.enable_bedrock ? 1 : 0
  name  = "BedrockAgentPolicy"
  role  = aws_iam_role.bedrock_agent_missing_scope[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "arn:aws:bedrock:*::foundation-model/*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Role: TrustFixDemo-BedrockKnowledgeBaseOverprivileged
# INTENTIONAL VULNERABILITY: AI_KB_EXCESSIVE_DATA_ACCESS
# -----------------------------------------------------------------------------
# A Bedrock Knowledge Base role with access to all S3 buckets,
# not just the specific knowledge base bucket.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "bedrock_kb_overprivileged" {
  count = var.enable_bedrock ? 1 : 0
  name  = "TrustFixDemo-BedrockKBOverprivileged"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Vulnerability   = "AI_KB_EXCESSIVE_DATA_ACCESS"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "Critical"
    ExpectedFinding = "Knowledge Base role can access all S3 buckets"
  }
}

resource "aws_iam_role_policy" "bedrock_kb_overprivileged_policy" {
  count = var.enable_bedrock ? 1 : 0
  name  = "KnowledgeBasePolicy"
  role  = aws_iam_role.bedrock_kb_overprivileged[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        # VULNERABILITY: Access to ALL S3 buckets, not just KB bucket
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = "*"
      }
    ]
  })
}
