#!/bin/bash
# =============================================================================
# TrustFix Demo Environment - Deploy Script
# =============================================================================
# This script deploys the intentionally vulnerable demo infrastructure.
# WARNING: Only deploy to sandbox/demo AWS accounts!
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║           TrustFix Demo Environment - Deployment Script                   ║"
echo "╠══════════════════════════════════════════════════════════════════════════╣"
echo "║                                                                           ║"
echo "║  ⚠️  WARNING: This deploys INTENTIONALLY VULNERABLE infrastructure!       ║"
echo "║                                                                           ║"
echo "║  Only deploy to sandbox/demo AWS accounts.                                ║"
echo "║  Never use in production.                                                 ║"
echo "║                                                                           ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check for terraform
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed. Please install Terraform >= 1.5.0"
    exit 1
fi

# Check for AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured. Please run 'aws configure' or set AWS_* environment variables."
    exit 1
fi

echo "AWS Account: $(aws sts get-caller-identity --query Account --output text)"
echo "AWS Region: ${AWS_REGION:-us-east-1}"
echo ""

# Check for terraform.tfvars
if [ ! -f "${TERRAFORM_DIR}/terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found."
    echo ""
    echo "Please create it with your GitHub organization:"
    echo ""
    echo "  cd ${TERRAFORM_DIR}"
    echo "  cat > terraform.tfvars << EOF"
    echo "  github_org = \"YOUR-GITHUB-ORG\""
    echo "  github_repo = \"trustfix-demo\""
    echo "  EOF"
    echo ""
    exit 1
fi

cd "${TERRAFORM_DIR}"

echo "Initializing Terraform..."
terraform init

echo ""
echo "Planning deployment..."
terraform plan -out=tfplan

echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
read -p "Deploy vulnerable infrastructure to AWS? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

echo ""
echo "Deploying..."
terraform apply tfplan
rm -f tfplan

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                     Deployment Complete!                                  ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo ""
echo "1. Copy the role ARNs from the output above to GitHub Secrets:"
echo "   Settings → Secrets and Variables → Actions → New repository secret"
echo ""
echo "2. Connect this repository to TrustFix:"
echo "   https://app.trustfix.dev → Settings → Integrations"
echo ""
echo "3. Connect your AWS account to TrustFix"
echo ""
echo "4. Run a TrustFix scan to see the findings"
echo ""
echo "When done, run: ./scripts/destroy.sh"
echo ""
