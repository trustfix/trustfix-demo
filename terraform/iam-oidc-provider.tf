# =============================================================================
# GitHub Actions OIDC Provider
# =============================================================================
# This configuration is CORRECT — the OIDC provider setup itself is standard.
# The vulnerabilities are in the IAM role trust policies that reference this
# provider, not in the provider configuration.
# =============================================================================

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name        = "GitHub-Actions-OIDC"
    Description = "OIDC provider for GitHub Actions workflows"
  }
}
