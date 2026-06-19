# TrustFix-generated permission policy — least-privilege scoped
resource "aws_iam_role_policy" "TrustFixDemo-OverprivilegedAdmin_inline" {
  name = "TrustFixDemo-OverprivilegedAdmin-policy"
  role = "TrustFixDemo-OverprivilegedAdmin"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ScopedArtifactsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::TrustFixDemo-OverprivilegedAdmin-artifacts",
          "arn:aws:s3:::TrustFixDemo-OverprivilegedAdmin-artifacts/*"
        ]
      }
    ]
  })
}
