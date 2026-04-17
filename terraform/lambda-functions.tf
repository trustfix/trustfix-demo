# =============================================================================
# INTENTIONALLY VULNERABLE Lambda Functions
# =============================================================================
# These Lambda functions demonstrate various Lambda-specific security issues
# that TrustFix should detect.
# =============================================================================

# -----------------------------------------------------------------------------
# Function 1: Lambda with Admin Execution Role
# INTENTIONAL VULNERABILITY: LAMBDA_EXECUTION_ROLE_ADMIN
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda_admin_role" {
  count = var.enable_lambda ? 1 : 0
  name  = "TrustFixDemo-LambdaAdminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Vulnerability   = "LAMBDA_EXECUTION_ROLE_ADMIN"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "Critical"
    ExpectedFinding = "Lambda execution role has AdministratorAccess"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_admin_policy" {
  count      = var.enable_lambda ? 1 : 0
  role       = aws_iam_role.lambda_admin_role[0].name
  # VULNERABILITY: Lambda should never have admin access
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_lambda_function" "admin_function" {
  count         = var.enable_lambda ? 1 : 0
  function_name = "trustfix-demo-admin-function"
  role          = aws_iam_role.lambda_admin_role[0].arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  filename         = data.archive_file.lambda_placeholder[0].output_path
  source_code_hash = data.archive_file.lambda_placeholder[0].output_base64sha256

  tags = {
    Vulnerability   = "LAMBDA_EXECUTION_ROLE_ADMIN"
    Intentional     = "true"
    TrustFixDemo    = "true"
    ExpectedFinding = "Lambda has admin execution role"
  }
}

# -----------------------------------------------------------------------------
# Function 2: Lambda with Unencrypted Environment Variables
# INTENTIONAL VULNERABILITY: LAMBDA_ENV_VARS_UNENCRYPTED
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda_basic_role" {
  count = var.enable_lambda ? 1 : 0
  name  = "TrustFixDemo-LambdaBasicRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    TrustFixDemo = "true"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
  count      = var.enable_lambda ? 1 : 0
  role       = aws_iam_role.lambda_basic_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "unencrypted_env" {
  count         = var.enable_lambda ? 1 : 0
  function_name = "trustfix-demo-unencrypted-env"
  role          = aws_iam_role.lambda_basic_role[0].arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  filename         = data.archive_file.lambda_placeholder[0].output_path
  source_code_hash = data.archive_file.lambda_placeholder[0].output_base64sha256

  environment {
    variables = {
      # VULNERABILITY: Sensitive-looking env vars without KMS encryption
      API_KEY         = "demo-api-key-12345"
      DATABASE_URL    = "postgresql://demo:demo@localhost:5432/demo"
      SECRET_TOKEN    = "demo-secret-token-intentionally-vulnerable"
      NORMAL_VAR      = "this-is-fine"
    }
  }

  # VULNERABILITY: No kms_key_arn specified for environment encryption
  # kms_key_arn = aws_kms_key.lambda_env.arn

  tags = {
    Vulnerability   = "LAMBDA_ENV_VARS_UNENCRYPTED"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "Medium"
    ExpectedFinding = "Lambda has sensitive env vars without KMS encryption"
  }
}

# -----------------------------------------------------------------------------
# Function 3: Lambda Function URL with No Auth
# INTENTIONAL VULNERABILITY: LAMBDA_FUNCTION_URL_NO_AUTH
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "public_url" {
  count         = var.enable_lambda ? 1 : 0
  function_name = "trustfix-demo-public-url"
  role          = aws_iam_role.lambda_basic_role[0].arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  filename         = data.archive_file.lambda_placeholder[0].output_path
  source_code_hash = data.archive_file.lambda_placeholder[0].output_base64sha256

  tags = {
    Vulnerability   = "LAMBDA_FUNCTION_URL_NO_AUTH"
    Intentional     = "true"
    TrustFixDemo    = "true"
    Severity        = "High"
    ExpectedFinding = "Lambda Function URL has no authentication"
  }
}

resource "aws_lambda_function_url" "public_url" {
  count              = var.enable_lambda ? 1 : 0
  function_name      = aws_lambda_function.public_url[0].function_name
  # VULNERABILITY: No authentication required
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

# -----------------------------------------------------------------------------
# Placeholder Lambda code (minimal handler)
# -----------------------------------------------------------------------------

data "archive_file" "lambda_placeholder" {
  count       = var.enable_lambda ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/lambda_placeholder.zip"

  source {
    content  = <<-EOT
      exports.handler = async (event) => {
        return {
          statusCode: 200,
          body: JSON.stringify({
            message: 'TrustFix Demo Lambda',
            warning: 'INTENTIONALLY VULNERABLE - Do not use in production'
          })
        };
      };
    EOT
    filename = "index.js"
  }
}
