# TrustFix-generated fix — GitHub Actions OIDC trust policy
resource "aws_iam_role" "TrustFixDemo-ForkPRRisk" {
  name = "TrustFixDemo-ForkPRRisk"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::018326344261:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:sub" = "repo:trustfix/trustfix-demo:environment:production"
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}
