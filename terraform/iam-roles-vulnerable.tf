# =============================================================================
# INTENTIONALLY VULNERABLE IAM ROLES
# =============================================================================
# These roles demonstrate various OIDC and IAM misconfigurations that TrustFix
# should detect. Each role has a specific vulnerability documented.
# =============================================================================

# -----------------------------------------------------------------------------
# Role 1: TrustFixDemo-MissingSubCondition
# INTENTIONAL VULNERABILITY: OIDC_MISSING_SUB_CONDITION
# -----------------------------------------------------------------------------
# This role allows ANY GitHub repository to assume it because there is no
# 'sub' condition in the trust policy. An attacker with any GitHub repo
# could create a workflow to assume this role.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "missing_sub_condition" {
  name = "TrustFixDemo-MissingSubCondition"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # VULNERABILITY: No 'sub' condition!
            # Missing: "token.actions.githubusercontent.com:sub" = "repo:org/repo:*"
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Vulnerability   = "OIDC_MISSING_SUB_CONDITION"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "Critical"
    ExpectedFinding = "Trust policy allows any GitHub repo to assume this role"
  }
}

resource "aws_iam_role_policy_attachment" "missing_sub_condition_policy" {
  role       = aws_iam_role.missing_sub_condition.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# -----------------------------------------------------------------------------
# Role 2: TrustFixDemo-OverprivilegedAdmin
# INTENTIONAL VULNERABILITY: OVERPRIVILEGED_ROLE
# -----------------------------------------------------------------------------
# This role has AdministratorAccess attached. Even though the trust policy
# is properly scoped, the role itself has excessive permissions.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "overprivileged_admin" {
  name = "TrustFixDemo-OverprivilegedAdmin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Vulnerability   = "OVERPRIVILEGED_ROLE"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "Critical"
    ExpectedFinding = "Role has AdministratorAccess - excessive permissions for CI/CD"
  }
}

resource "aws_iam_role_policy_attachment" "overprivileged_admin_policy" {
  role       = aws_iam_role.overprivileged_admin.name
  # VULNERABILITY: AdministratorAccess is far more than any workflow needs
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# -----------------------------------------------------------------------------
# Role 3: TrustFixDemo-WildcardEnvironment
# INTENTIONAL VULNERABILITY: OIDC_WILDCARD_ENVIRONMENT
# -----------------------------------------------------------------------------
# This role's trust policy uses "environment:*" wildcard, allowing any
# GitHub environment to assume the role. This defeats environment-based
# access controls.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "wildcard_environment" {
  name = "TrustFixDemo-WildcardEnvironment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # VULNERABILITY: Wildcard environment allows ANY environment
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:environment:*"
          }
        }
      }
    ]
  })

  tags = {
    Vulnerability   = "OIDC_WILDCARD_ENVIRONMENT"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "High"
    ExpectedFinding = "Trust policy uses environment:* wildcard"
  }
}

resource "aws_iam_role_policy_attachment" "wildcard_environment_policy" {
  role       = aws_iam_role.wildcard_environment.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# -----------------------------------------------------------------------------
# Role 4: TrustFixDemo-ForkPRRisk
# INTENTIONAL VULNERABILITY: OIDC_FORK_PR_RISK
# -----------------------------------------------------------------------------
# This role can be assumed by pull_request events, which include PRs from
# forks. An attacker could fork the repo, modify the workflow, and their
# PR would trigger execution with this role's permissions.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "fork_pr_risk" {
  name = "TrustFixDemo-ForkPRRisk"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # VULNERABILITY: pull_request includes forks!
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:pull_request"
          }
        }
      }
    ]
  })

  tags = {
    Vulnerability   = "OIDC_FORK_PR_RISK"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "High"
    ExpectedFinding = "Role can be assumed by PRs from forks"
  }
}

resource "aws_iam_role_policy" "fork_pr_risk_policy" {
  name = "S3WriteAccess"
  role = aws_iam_role.fork_pr_risk.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.demo_data.arn,
          "${aws_s3_bucket.demo_data.arn}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Role 5: TrustFixDemo-MissingAudCondition
# INTENTIONAL VULNERABILITY: OIDC_MISSING_AUD_CONDITION
# -----------------------------------------------------------------------------
# This role has a 'sub' condition but no 'aud' (audience) condition.
# While less severe than missing 'sub', this is still a security gap.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "missing_aud_condition" {
  name = "TrustFixDemo-MissingAudCondition"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
          }
          # VULNERABILITY: No 'aud' condition!
          # Missing: "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Vulnerability   = "OIDC_MISSING_AUD_CONDITION"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "Medium"
    ExpectedFinding = "Trust policy missing audience (aud) condition"
  }
}

resource "aws_iam_role_policy_attachment" "missing_aud_condition_policy" {
  role       = aws_iam_role.missing_aud_condition.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# -----------------------------------------------------------------------------
# Role 6: TrustFixDemo-ExpiredOIDCProvider
# INTENTIONAL VULNERABILITY: OIDC_EXPIRED_OIDC_PROVIDER
# -----------------------------------------------------------------------------
# This role references an OIDC provider with a hardcoded (potentially stale)
# thumbprint, simulating an expired or outdated OIDC provider configuration.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "expired_oidc" {
  name = "TrustFixDemo-ExpiredOIDCProvider"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # VULNERABILITY: References OIDC provider that may have stale thumbprint
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Vulnerability   = "OIDC_EXPIRED_OIDC_PROVIDER"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "Medium"
    ExpectedFinding = "OIDC provider thumbprint may be stale or expired"
    ThumbprintNote  = "In real scenarios, TrustFix detects providers with outdated thumbprints"
  }
}

resource "aws_iam_role_policy_attachment" "expired_oidc_policy" {
  role       = aws_iam_role.expired_oidc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# -----------------------------------------------------------------------------
# Role 7: TrustFixDemo-Correct (CONTROL CASE)
# This role is CORRECTLY CONFIGURED - TrustFix should NOT flag it
# -----------------------------------------------------------------------------
# Demonstrates secure OIDC configuration with:
# - Specific 'sub' condition (repo + branch)
# - 'aud' condition for audience validation
# - Minimal, scoped permissions
# -----------------------------------------------------------------------------

resource "aws_iam_role" "correct" {
  name = "TrustFixDemo-Correct"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # CORRECT: Specific audience condition
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringEquals = {
            # CORRECT: Specific sub condition with branch
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Vulnerability   = "NONE"
    Intentional     = "false"
    TrustFixDemo    = "true"
    Severity        = "N/A"
    ExpectedFinding = "VERIFIED - This role is correctly configured"
    ControlCase     = "true"
  }
}

resource "aws_iam_role_policy" "correct_policy" {
  name = "MinimalS3ReadAccess"
  role = aws_iam_role.correct.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.demo_data.arn,
          "${aws_s3_bucket.demo_data.arn}/*"
        ]
      }
    ]
  })
}
