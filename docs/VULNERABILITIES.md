# TrustFix Demo - Vulnerability Catalog

This document catalogs every intentional vulnerability in this demo environment. Use this as a reference for what TrustFix should detect.

---

## Summary

| Finding Code | Severity | Category | Count |
|-------------|----------|----------|-------|
| `OIDC_MISSING_SUB_CONDITION` | Critical | OIDC | 1 |
| `OIDC_MISSING_AUD_CONDITION` | Medium | OIDC | 1 |
| `OIDC_WILDCARD_ENVIRONMENT` | High | OIDC | 1 |
| `OIDC_FORK_PR_RISK` | High | OIDC | 1 |
| `OIDC_EXPIRED_OIDC_PROVIDER` | Medium | OIDC | 1 |
| `OVERPRIVILEGED_ROLE` | Critical | IAM | 1 |
| `OVERPRIVILEGED_ADMIN_ROLE` | Critical | IAM | 1 |
| `STALE_PRIVILEGED_CREDENTIALS` | High | IAM | 1 |
| `CROSS_ACCOUNT_ADMIN_TRUST` | Critical | IAM | 1 |
| `AI_AGENT_OVERPRIVILEGED_ROLE` | Critical | AI/ML | 1 |
| `AI_AGENT_MISSING_SCOPE_CONDITION` | High | AI/ML | 1 |
| `AI_KB_EXCESSIVE_DATA_ACCESS` | Critical | AI/ML | 1 |
| `LAMBDA_EXECUTION_ROLE_ADMIN` | Critical | Lambda | 1 |
| `LAMBDA_ENV_VARS_UNENCRYPTED` | Medium | Lambda | 1 |
| `LAMBDA_FUNCTION_URL_NO_AUTH` | High | Lambda | 1 |

---

## OIDC Vulnerabilities

### OIDC_MISSING_SUB_CONDITION

**Severity**: Critical

**File**: `terraform/iam-roles-vulnerable.tf` (lines 1-50)

**Why It's Vulnerable**:

The IAM role `TrustFixDemo-MissingSubCondition` has an OIDC trust policy that accepts tokens from GitHub Actions but does NOT validate the `sub` (subject) claim. The `sub` claim identifies which repository and workflow is requesting access.

Without this condition, ANY GitHub repository in the world can create a workflow that assumes this role. An attacker could:
1. Create their own GitHub repository
2. Add a workflow that assumes this role
3. Access all resources the role can access (S3 data, etc.)

**What TrustFix Should Detect**:
- Trust policy missing `token.actions.githubusercontent.com:sub` condition
- Role is accessible from any GitHub repository
- High blast radius due to S3 read permissions

**What the Fix PR Should Contain**:
```hcl
Condition = {
  StringEquals = {
    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
+   "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
  }
}
```

---

### OIDC_MISSING_AUD_CONDITION

**Severity**: Medium

**File**: `terraform/iam-roles-vulnerable.tf` (lines 137-170)

**Why It's Vulnerable**:

The IAM role `TrustFixDemo-MissingAudCondition` validates the `sub` claim but NOT the `aud` (audience) claim. The audience claim verifies that the token was intended for AWS STS.

While less severe than missing `sub`, this opens the door to token confusion attacks where a token intended for a different service could be replayed.

**What TrustFix Should Detect**:
- Trust policy missing `token.actions.githubusercontent.com:aud` condition
- Potential token confusion vulnerability

**What the Fix PR Should Contain**:
```hcl
Condition = {
  StringLike = {
    "token.actions.githubusercontent.com:sub" = "repo:org/repo:ref:refs/heads/main"
  }
+ StringEquals = {
+   "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
+ }
}
```

---

### OIDC_WILDCARD_ENVIRONMENT

**Severity**: High

**File**: `terraform/iam-roles-vulnerable.tf` (lines 67-100)

**Why It's Vulnerable**:

The IAM role `TrustFixDemo-WildcardEnvironment` uses `environment:*` in its sub condition. GitHub Environments are a protection mechanism — production environments require approvals.

Using a wildcard bypasses this protection. An attacker with repo write access could:
1. Create a new environment named "attacker-env"
2. Run a workflow in that environment (no approvals needed)
3. Assume this role with the same permissions as production

**What TrustFix Should Detect**:
- Wildcard in environment claim
- Environment-based access control bypassed

**What the Fix PR Should Contain**:
```hcl
StringLike = {
- "token.actions.githubusercontent.com:sub" = "repo:org/repo:environment:*"
+ "token.actions.githubusercontent.com:sub" = "repo:org/repo:environment:production"
}
```

---

### OIDC_FORK_PR_RISK

**Severity**: High

**File**: `terraform/iam-roles-vulnerable.tf` (lines 102-135)

**Why It's Vulnerable**:

The IAM role `TrustFixDemo-ForkPRRisk` allows assumption from `pull_request` events. By default, GitHub's `pull_request` trigger runs on PRs from forks.

An attacker could:
1. Fork the repository
2. Modify the workflow to exfiltrate credentials
3. Open a PR — the workflow runs with AWS access
4. Steal data or deploy malicious resources

**What TrustFix Should Detect**:
- Trust policy allows `pull_request` event type
- Role has write permissions (S3 PutObject)
- Correlation with workflow using `on: pull_request`

**What the Fix PR Should Contain**:
```hcl
StringLike = {
- "token.actions.githubusercontent.com:sub" = "repo:org/repo:pull_request"
+ "token.actions.githubusercontent.com:sub" = "repo:org/repo:ref:refs/heads/main"
}
```

---

## IAM Vulnerabilities

### OVERPRIVILEGED_ROLE

**Severity**: Critical

**File**: `terraform/iam-roles-vulnerable.tf` (lines 52-65)

**Why It's Vulnerable**:

The IAM role `TrustFixDemo-OverprivilegedAdmin` has `AdministratorAccess` attached. Even though the trust policy is properly scoped, this role can:
- Create/delete any AWS resource
- Modify IAM policies and users
- Access all data in the account
- Disable security controls

No CI/CD workflow needs admin access. If the workflow is compromised, attackers have full account access.

**What TrustFix Should Detect**:
- `AdministratorAccess` managed policy attached
- Role intended for CI/CD use
- Excessive blast radius

**What the Fix PR Should Contain**:
Custom least-privilege policy with only required actions (e.g., specific S3 and CloudFront permissions for a deploy workflow).

---

### OVERPRIVILEGED_ADMIN_ROLE

**Severity**: Critical

**File**: `terraform/iam-roles-overprivileged.tf`

**Why It's Vulnerable**:

The IAM role `TrustFixDemo-ServiceAccountAdmin` is an EC2 service role with `AdministratorAccess`. Any EC2 instance with this instance profile can perform any AWS action.

A compromised EC2 instance becomes a full account compromise.

---

### STALE_PRIVILEGED_CREDENTIALS

**Severity**: High

**File**: `terraform/iam-roles-overprivileged.tf`

**Why It's Vulnerable**:

The IAM user `TrustFixDemo-UnusedAdminKey` has admin access. The tags simulate a credential that hasn't been used since 2024-01-15. Stale admin credentials are:
- Forgotten by teams
- Not rotated
- Perfect targets for attackers

---

### CROSS_ACCOUNT_ADMIN_TRUST

**Severity**: Critical

**File**: `terraform/iam-roles-overprivileged.tf`

**Why It's Vulnerable**:

The IAM role `TrustFixDemo-CrossAccountOverprivileged` trusts another AWS account without an external ID. The "confused deputy" problem means the trusted account could be tricked into assuming this role on behalf of an attacker.

---

## AI/ML Vulnerabilities

### AI_AGENT_OVERPRIVILEGED_ROLE

**Severity**: Critical

**File**: `terraform/bedrock-agent-misconfigured.tf`

**Why It's Vulnerable**:

The Bedrock agent role has `bedrock:*`, `s3:*`, and `lambda:InvokeFunction` on all resources. An AI agent with these permissions could:
- Invoke any model (cost explosion)
- Access any S3 data (data exfiltration)
- Invoke any Lambda (privilege escalation)

AI agents should have minimal, scoped permissions.

---

### AI_AGENT_MISSING_SCOPE_CONDITION

**Severity**: High

**File**: `terraform/bedrock-agent-misconfigured.tf`

**Why It's Vulnerable**:

The trust policy has no conditions restricting which Bedrock agents can assume the role. Should include:
- `aws:SourceAccount` condition
- `aws:SourceArn` for specific agent ARN

---

## Lambda Vulnerabilities

### LAMBDA_EXECUTION_ROLE_ADMIN

**Severity**: Critical

**File**: `terraform/lambda-functions.tf`

**Why It's Vulnerable**:

The Lambda function's execution role has `AdministratorAccess`. A code injection vulnerability in this function equals full account compromise.

---

### LAMBDA_ENV_VARS_UNENCRYPTED

**Severity**: Medium

**File**: `terraform/lambda-functions.tf`

**Why It's Vulnerable**:

Environment variables containing `API_KEY`, `DATABASE_URL`, and `SECRET_TOKEN` are stored without KMS encryption. Anyone with Lambda read access can see these values.

---

### LAMBDA_FUNCTION_URL_NO_AUTH

**Severity**: High

**File**: `terraform/lambda-functions.tf`

**Why It's Vulnerable**:

The Function URL has `authorization_type = "NONE"`. Anyone on the internet can invoke this function. Combined with overprivileged execution roles, this is a direct path to compromise.

---

## Control Case

### TrustFixDemo-Correct

**File**: `terraform/iam-roles-vulnerable.tf` (lines 200-250)

This role is **correctly configured**. TrustFix should:
- NOT flag it as vulnerable
- Mark it as `VERIFIED` or show a green status
- Use it as a baseline comparison

Correct configuration:
- Specific `sub` condition (repo + branch)
- `aud` condition for audience validation
- Minimal, scoped IAM policy
- Environment-gated deployment
