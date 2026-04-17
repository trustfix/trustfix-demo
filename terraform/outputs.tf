# =============================================================================
# TrustFix Demo Environment - Outputs
# =============================================================================
# These outputs provide the role ARNs needed to configure GitHub Secrets.
# Copy these values to your GitHub repository secrets.
# =============================================================================

output "setup_instructions" {
  description = "Next steps to connect TrustFix"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                    TrustFix Demo Environment Ready!                       ║
    ╚══════════════════════════════════════════════════════════════════════════╝

    TrustFix Scanner Setup
    ═══════════════════════

    To connect this AWS account to TrustFix:

    1. Go to TrustFix → Settings → Integrations → AWS → Add Account
    2. Enter the following values:
       - Role ARN: ${aws_iam_role.trustfix_scanner.arn}
       - External ID: (run 'terraform output -raw trustfix_external_id')
    3. Click "Verify Connection"
    4. TrustFix will perform its first scan automatically

    GitHub Secrets Setup
    ════════════════════

    Copy these role ARNs to GitHub repository secrets:
    Settings → Secrets and Variables → Actions → New repository secret

    SECURITY NOTES:
    - The scanner role is READ-ONLY. TrustFix cannot modify your AWS resources.
    - The external ID is a shared secret. Never share it publicly.
    - To revoke access: terraform destroy (or delete the TrustFixScanner role)
    - All TrustFix access is logged in CloudTrail for audit

  EOT
}

# -----------------------------------------------------------------------------
# OIDC Provider
# -----------------------------------------------------------------------------

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

# -----------------------------------------------------------------------------
# Vulnerable Role ARNs (for GitHub Secrets)
# -----------------------------------------------------------------------------

output "vulnerable_role_arn" {
  description = "GitHub Secret: AWS_ROLE_VULNERABLE - Role missing sub condition"
  value       = aws_iam_role.missing_sub_condition.arn
}

output "overprivileged_role_arn" {
  description = "GitHub Secret: AWS_ROLE_OVERPRIVILEGED - Role with AdministratorAccess"
  value       = aws_iam_role.overprivileged_admin.arn
}

output "wildcard_env_role_arn" {
  description = "GitHub Secret: AWS_ROLE_WILDCARD_ENV - Role with environment:* wildcard"
  value       = aws_iam_role.wildcard_environment.arn
}

output "fork_pr_role_arn" {
  description = "GitHub Secret: AWS_ROLE_FORK_PR - Role assumable by fork PRs"
  value       = aws_iam_role.fork_pr_risk.arn
}

output "secure_role_arn" {
  description = "GitHub Secret: AWS_ROLE_SECURE - Correctly configured role (control case)"
  value       = aws_iam_role.correct.arn
}

# -----------------------------------------------------------------------------
# Additional Role ARNs
# -----------------------------------------------------------------------------

output "missing_aud_role_arn" {
  description = "Role missing audience condition"
  value       = aws_iam_role.missing_aud_condition.arn
}

output "broad_repo_pattern_role_arn" {
  description = "Role with broad org-wide repo pattern wildcard"
  value       = aws_iam_role.broad_repo_pattern.arn
}

output "service_account_admin_role_arn" {
  description = "EC2 service role with admin access"
  value       = aws_iam_role.service_account_admin.arn
}

output "cross_account_admin_role_arn" {
  description = "Cross-account role with admin access (no external ID)"
  value       = aws_iam_role.cross_account_admin.arn
}

# -----------------------------------------------------------------------------
# Bedrock Role ARNs (conditional)
# -----------------------------------------------------------------------------

output "bedrock_overprivileged_role_arn" {
  description = "Bedrock agent role with excessive permissions"
  value       = var.enable_bedrock ? aws_iam_role.bedrock_agent_overprivileged[0].arn : "Not created (enable_bedrock=false)"
}

output "bedrock_missing_scope_role_arn" {
  description = "Bedrock agent role missing scope conditions"
  value       = var.enable_bedrock ? aws_iam_role.bedrock_agent_missing_scope[0].arn : "Not created (enable_bedrock=false)"
}

# -----------------------------------------------------------------------------
# Lambda ARNs (conditional)
# -----------------------------------------------------------------------------

output "lambda_admin_function_arn" {
  description = "Lambda function with admin execution role"
  value       = var.enable_lambda ? aws_lambda_function.admin_function[0].arn : "Not created (enable_lambda=false)"
}

output "lambda_public_url" {
  description = "Lambda function URL with no authentication"
  value       = var.enable_lambda ? aws_lambda_function_url.public_url[0].function_url : "Not created (enable_lambda=false)"
}

# -----------------------------------------------------------------------------
# S3 Bucket Names
# -----------------------------------------------------------------------------

output "demo_data_bucket" {
  description = "S3 bucket for demo data"
  value       = aws_s3_bucket.demo_data.id
}

output "demo_artifacts_bucket" {
  description = "S3 bucket for CI/CD artifacts"
  value       = aws_s3_bucket.demo_artifacts.id
}

# -----------------------------------------------------------------------------
# Summary for GitHub Secrets
# -----------------------------------------------------------------------------

output "github_secrets_summary" {
  description = "Summary of GitHub Secrets to configure"
  value       = <<-EOT

    ═══════════════════════════════════════════════════════════════════════════
    GitHub Secrets to Configure:
    ═══════════════════════════════════════════════════════════════════════════

    AWS_ROLE_VULNERABLE      = ${aws_iam_role.missing_sub_condition.arn}
    AWS_ROLE_OVERPRIVILEGED  = ${aws_iam_role.overprivileged_admin.arn}
    AWS_ROLE_WILDCARD_ENV    = ${aws_iam_role.wildcard_environment.arn}
    AWS_ROLE_FORK_PR         = ${aws_iam_role.fork_pr_risk.arn}
    AWS_ROLE_SECURE          = ${aws_iam_role.correct.arn}

    ═══════════════════════════════════════════════════════════════════════════

  EOT
}

# -----------------------------------------------------------------------------
# TrustFix Scanner Role
# -----------------------------------------------------------------------------

output "trustfix_scanner_role_arn" {
  description = "ARN of the TrustFix scanner role. Copy this into TrustFix when connecting this AWS account."
  value       = aws_iam_role.trustfix_scanner.arn
}

output "trustfix_external_id" {
  description = "External ID for TrustFix connection. Provide this to TrustFix when setting up the connection. Keep this secret."
  value       = random_uuid.trustfix_external_id.result
  sensitive   = true
}
