# =============================================================================
# INTENTIONALLY VULNERABLE IAM ROLES - Non-OIDC Privilege Issues
# =============================================================================
# These roles demonstrate overprivileged service accounts and stale
# credentials that TrustFix should detect.
# =============================================================================

# -----------------------------------------------------------------------------
# Role: TrustFixDemo-ServiceAccountAdmin
# INTENTIONAL VULNERABILITY: OVERPRIVILEGED_ADMIN_ROLE
# -----------------------------------------------------------------------------
# An EC2 service role with AdministratorAccess. This is a common
# misconfiguration where EC2 instances are given far more permissions
# than they need.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "service_account_admin" {
  name = "TrustFixDemo-ServiceAccountAdmin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Vulnerability   = "OVERPRIVILEGED_ADMIN_ROLE"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "Critical"
    ExpectedFinding = "EC2 service role has AdministratorAccess"
  }
}

resource "aws_iam_role_policy_attachment" "service_account_admin_policy" {
  role = aws_iam_role.service_account_admin.name
  # VULNERABILITY: EC2 instances should never have admin access
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "service_account_admin" {
  name = "TrustFixDemo-ServiceAccountAdmin"
  role = aws_iam_role.service_account_admin.name
}

# -----------------------------------------------------------------------------
# User: TrustFixDemo-UnusedAdminKey
# INTENTIONAL VULNERABILITY: STALE_PRIVILEGED_CREDENTIALS
# -----------------------------------------------------------------------------
# An IAM user with admin access and access keys. The tags simulate
# a stale/unused credential scenario.
# -----------------------------------------------------------------------------

resource "aws_iam_user" "unused_admin_key" {
  name = "TrustFixDemo-UnusedAdminKey"

  tags = {
    Vulnerability     = "STALE_PRIVILEGED_CREDENTIALS"
    Intentional       = "true"
    TrustFixDemo      = "true"
    Severity          = "High"
    ExpectedFinding   = "Admin user with potentially unused access keys"
    SimulatedLastUsed = "2024-01-15"
    CreatedFor        = "Demo - simulates stale credential"
  }
}

resource "aws_iam_user_policy_attachment" "unused_admin_key_policy" {
  user = aws_iam_user.unused_admin_key.name
  # VULNERABILITY: User has admin access
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Note: We don't actually create access keys here to avoid creating real
# credentials. The vulnerability demonstration is in the user/policy setup.
# TrustFix would detect this user's policy attachment regardless.

# -----------------------------------------------------------------------------
# Role: TrustFixDemo-CrossAccountOverprivileged
# INTENTIONAL VULNERABILITY: CROSS_ACCOUNT_ADMIN_TRUST
# -----------------------------------------------------------------------------
# A role that trusts another AWS account with admin permissions.
# This simulates overly permissive cross-account access.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "cross_account_admin" {
  name = "TrustFixDemo-CrossAccountOverprivileged"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # VULNERABILITY: Trusts account with no external ID condition
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        # Missing: Condition with external ID for security
      }
    ]
  })

  tags = {
    Vulnerability   = "CROSS_ACCOUNT_ADMIN_TRUST"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "Critical"
    ExpectedFinding = "Admin role trusted without external ID condition"
  }
}

resource "aws_iam_role_policy_attachment" "cross_account_admin_policy" {
  role       = aws_iam_role.cross_account_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
