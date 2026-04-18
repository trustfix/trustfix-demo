# TrustFix-generated permission policy — least-privilege scoped
resource "aws_iam_role_policy" "TrustFixDemo-ServiceAccountAdmin_inline" {
  name = "TrustFixDemo-ServiceAccountAdmin-policy"
  role = "TrustFixDemo-ServiceAccountAdmin"
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
          "arn:aws:s3:::TrustFixDemo-ServiceAccountAdmin-artifacts",
          "arn:aws:s3:::TrustFixDemo-ServiceAccountAdmin-artifacts/*"
        ]
      }
    ]
  })
}
