#!/bin/bash
# =============================================================================
# TrustFix Demo Environment - Destroy Script
# =============================================================================
# This script tears down all demo infrastructure from AWS.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║           TrustFix Demo Environment - Destroy Script                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check for terraform
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed."
    exit 1
fi

# Check for AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured."
    exit 1
fi

echo "AWS Account: $(aws sts get-caller-identity --query Account --output text)"
echo ""

cd "${TERRAFORM_DIR}"

# Check if state exists
if [ ! -f "terraform.tfstate" ] && [ ! -d ".terraform" ]; then
    echo "No Terraform state found. Nothing to destroy."
    exit 0
fi

echo "This will destroy all TrustFix demo resources in AWS."
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Destroy cancelled."
    exit 0
fi

echo ""
echo "Destroying infrastructure..."
terraform destroy -auto-approve

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                    Demo Environment Destroyed                             ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "All demo resources have been removed from AWS."
echo ""
echo "Thank you for using TrustFix!"
echo ""
echo "Questions? Contact us at support@trustfix.dev"
echo ""
