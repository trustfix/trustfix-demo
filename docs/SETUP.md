# TrustFix Demo Environment - Setup Guide

This guide walks you through deploying the TrustFix demo environment to your own GitHub organization and AWS account.

---

## Prerequisites

- **GitHub Account** with permission to create repositories
- **AWS Account** (sandbox/demo account recommended)
- **Terraform** >= 1.5.0 installed locally
- **AWS CLI** configured with credentials
- **Git** installed locally

---

## Cost Estimate

| Resource | Monthly Cost |
|----------|-------------|
| IAM Roles | Free |
| OIDC Provider | Free |
| S3 Buckets (empty) | ~$0.03 |
| Lambda Functions | ~$0 (free tier) |
| **Total (without Bedrock)** | **~$0-1/month** |
| Bedrock (if enabled) | ~$5-50/month (usage-based) |

**Recommendation**: Run `terraform destroy` when not actively demoing.

---

## Step 1: Fork or Clone the Repository

### Option A: Fork (Recommended for demos)

1. Go to [github.com/trustfix/trustfix-demo](https://github.com/trustfix/trustfix-demo)
2. Click **Fork** in the upper right
3. Select your organization or personal account
4. Clone your fork locally:

```bash
git clone https://github.com/YOUR-ORG/trustfix-demo.git
cd trustfix-demo
```

### Option B: Clone directly

```bash
git clone https://github.com/trustfix/trustfix-demo.git
cd trustfix-demo
```

---

## Step 2: Configure AWS Credentials

Ensure you have AWS credentials configured for your sandbox account:

```bash
# Option 1: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# Option 2: AWS CLI profile
aws configure --profile trustfix-demo
export AWS_PROFILE=trustfix-demo

# Verify access
aws sts get-caller-identity
```

---

## Step 3: Configure Terraform Variables

```bash
cd terraform

# Create your variables file
cat > terraform.tfvars << EOF
github_org     = "YOUR-GITHUB-ORG"  # Replace with your org/username
github_repo    = "trustfix-demo"
aws_region     = "us-east-1"
enable_bedrock = false              # Set to true if you want Bedrock demos
enable_lambda  = true
EOF
```

---

## Step 4: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Deploy (type 'yes' when prompted)
terraform apply
```

Expected output:
```
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:

github_secrets_summary = <<EOT

═══════════════════════════════════════════════════════════════════════════
GitHub Secrets to Configure:
═══════════════════════════════════════════════════════════════════════════

AWS_ROLE_VULNERABLE      = arn:aws:iam::123456789012:role/TrustFixDemo-MissingSubCondition
AWS_ROLE_OVERPRIVILEGED  = arn:aws:iam::123456789012:role/TrustFixDemo-OverprivilegedAdmin
...

EOT
```

---

## Step 5: Configure GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret from the Terraform output:

| Secret Name | Value (from Terraform output) |
|------------|-------------------------------|
| `AWS_ROLE_VULNERABLE` | `arn:aws:iam::...:role/TrustFixDemo-MissingSubCondition` |
| `AWS_ROLE_OVERPRIVILEGED` | `arn:aws:iam::...:role/TrustFixDemo-OverprivilegedAdmin` |
| `AWS_ROLE_WILDCARD_ENV` | `arn:aws:iam::...:role/TrustFixDemo-WildcardEnvironment` |
| `AWS_ROLE_FORK_PR` | `arn:aws:iam::...:role/TrustFixDemo-ForkPRRisk` |
| `AWS_ROLE_SECURE` | `arn:aws:iam::...:role/TrustFixDemo-Correct` |

---

## Step 6: Connect to TrustFix

1. Log in to [TrustFix](https://app.trustfix.dev)
2. **Connect GitHub**:
   - Settings → Integrations → GitHub
   - Authorize TrustFix for your organization
   - Select the `trustfix-demo` repository
3. **Connect AWS**:
   - Settings → Integrations → AWS
   - Follow the CloudFormation stack deployment
   - Select your demo AWS account

---

## Step 7: Run TrustFix Scan

1. Go to the TrustFix Dashboard
2. Click **New Scan**
3. Select the `trustfix-demo` repository
4. Select your demo AWS account
5. Click **Start Scan**

Expected findings:
- Critical: `OIDC_MISSING_SUB_CONDITION`, `OVERPRIVILEGED_ROLE`
- High: `OIDC_WILDCARD_ENVIRONMENT`, `OIDC_FORK_PR_RISK`
- Medium: `OIDC_MISSING_AUD_CONDITION`

---

## Step 8: Clean Up (When Done)

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted. This removes all demo resources from AWS.

---

## How TrustFix Access Works

TrustFix uses AWS cross-account role assumption with external ID for security:

1. **Cross-Account Trust:** Only TrustFix's AWS account can assume the TrustFixScanner role
2. **External ID:** A unique shared secret required for every assumption
3. **Read-Only:** The role has ZERO write permissions across any AWS service
4. **Explicit Deny:** The role explicitly denies all write actions as defense-in-depth
5. **Audit Trail:** Every assume-role and API call is logged in CloudTrail

### What TrustFix CAN do:

- List and describe IAM roles, users, policies
- Read trust policies and permissions
- Discover OIDC providers and their configurations
- Enumerate Lambda functions and their configs
- Discover Bedrock agents and their IAM roles
- Query CloudTrail for identity usage patterns

### What TrustFix CANNOT do:

- Modify ANY AWS resource
- Read S3 object contents
- Access secrets in Secrets Manager
- Decrypt data via KMS
- Invoke Lambda functions
- Create, modify, or delete IAM entities
- Access billing or organizations management

### Revoking Access

To revoke TrustFix access at any time:

**Option 1:** Remove just the scanner role:
```bash
aws iam delete-role --role-name TrustFixScanner
```

**Option 2:** Destroy the entire demo environment:
```bash
cd terraform && terraform destroy
```

### Auditing TrustFix Activity

All TrustFix API calls appear in CloudTrail with:
- `eventSource` matching the service being queried
- `userIdentity.principalId` containing "TrustFixScanner"
- `sourceIPAddress` from TrustFix's infrastructure

Query example:
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=TrustFixScanner
```

---

## Troubleshooting

### "Error assuming role"

The GitHub OIDC workflow can't assume the IAM role. Check:
- The `github_org` variable matches your actual GitHub org
- The OIDC provider was created successfully
- GitHub Secrets contain the correct role ARNs

### "Terraform state lock"

Someone else is running Terraform, or a previous run crashed. Wait or run:
```bash
terraform force-unlock LOCK_ID
```

### "Access Denied" in AWS

Your local AWS credentials may lack permissions. The deploying user needs:
- `iam:*` (for creating roles and OIDC provider)
- `s3:*` (for creating buckets)
- `lambda:*` (for creating functions)

---

## Next Steps

After scanning with TrustFix:

1. Review the findings in the TrustFix dashboard
2. Click into each finding to see details
3. Click **Generate Fix** to create a remediation PR
4. Observe the Trust Score change

See [DEMO_SCRIPT.md](DEMO_SCRIPT.md) for a guided walkthrough.
