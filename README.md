<p align="center">
  <img src="https://trustfix.dev/logo.png" alt="TrustFix Logo" width="200"/>
</p>

<h1 align="center">TrustFix Demo Environment</h1>

<p align="center">
  <strong>Non-Human Identity Security Platform</strong><br/>
  Detect, prioritize, and remediate NHI vulnerabilities automatically
</p>

---

## ⚠️ WARNING: INTENTIONALLY VULNERABLE

> **This repository contains INTENTIONALLY VULNERABLE infrastructure configurations.**
> 
> **DO NOT deploy to production AWS accounts.**
> 
> This is a demonstration environment designed to showcase TrustFix's detection and remediation capabilities. All vulnerabilities are documented and labeled.

---

## Security Model

This demo includes a TrustFix scanner IAM role with:

- ✅ **READ-ONLY access** — no write permissions anywhere
- ✅ **External ID protection** — shared secret required for assumption
- ✅ **Explicit deny on all write actions** — defense in depth
- ✅ **CloudTrail audit logging** — all access is logged
- ✅ **Scoped to security-relevant APIs only**

TrustFix CANNOT modify your AWS resources. It can only READ configurations to detect misconfigurations. Fix PRs are generated in GitHub and require human review before any AWS changes happen.

---

## Purpose

This repository demonstrates what [TrustFix](https://trustfix.dev) detects and automatically fixes:

- **OIDC Misconfigurations** — Missing sub conditions, wildcard environments, fork PR risks
- **Overprivileged Roles** — Service accounts with admin access
- **AI Agent Security** — Bedrock agents with excessive permissions
- **Lambda Misconfigurations** — Admin execution roles, unencrypted env vars

Use this to evaluate TrustFix or run live demos for prospects, investors, and partners.

---

## Quick Start

```bash
# 1. Clone and configure
git clone https://github.com/trustfix/trustfix-demo.git
cd trustfix-demo/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GitHub org

# 2. Deploy to sandbox AWS
terraform init
terraform apply

# 3. Connect to TrustFix and scan
# Copy role ARNs from output to GitHub Secrets, then run TrustFix scan
```

See [docs/SETUP.md](docs/SETUP.md) for detailed instructions.

---

## Vulnerabilities Included

| Finding Code | Severity | Location | Description |
|-------------|----------|----------|-------------|
| `OIDC_MISSING_SUB_CONDITION` | Critical | `iam-roles-vulnerable.tf` | Role allows ANY GitHub repo to assume it |
| `OIDC_WILDCARD_ENVIRONMENT` | High | `iam-roles-vulnerable.tf` | Trust policy uses `environment:*` wildcard |
| `OIDC_FORK_PR_RISK` | High | `iam-roles-vulnerable.tf` | Role can be assumed from forked PR workflows |
| `OIDC_MISSING_AUD_CONDITION` | Medium | `iam-roles-vulnerable.tf` | Missing audience validation in trust policy |
| `OVERPRIVILEGED_ROLE` | Critical | `iam-roles-vulnerable.tf` | Role has AdministratorAccess attached |
| `OVERPRIVILEGED_ADMIN_ROLE` | Critical | `iam-roles-overprivileged.tf` | EC2 service role with admin access |
| `STALE_PRIVILEGED_CREDENTIALS` | High | `iam-roles-overprivileged.tf` | Admin user with potentially unused access keys |
| `AI_AGENT_OVERPRIVILEGED_ROLE` | Critical | `bedrock-agent-misconfigured.tf` | Bedrock agent with `bedrock:*` permissions |
| `LAMBDA_EXECUTION_ROLE_ADMIN` | Critical | `lambda-functions.tf` | Lambda with admin execution role |
| `LAMBDA_ENV_VARS_UNENCRYPTED` | Medium | `lambda-functions.tf` | Sensitive env vars without KMS encryption |
| `LAMBDA_FUNCTION_URL_NO_AUTH` | High | `lambda-functions.tf` | Function URL without authentication |

---

## Expected TrustFix Findings After Scan

After connecting this repo and AWS account to TrustFix, expect these findings:

| Finding Code | Severity | File | What TrustFix Should Detect |
|-------------|----------|------|---------------------------|
| `OIDC_MISSING_SUB_CONDITION` | 🔴 Critical | `terraform/iam-roles-vulnerable.tf:1-30` | Trust policy allows GitHub OIDC without `sub` claim validation |
| `OVERPRIVILEGED_ROLE` | 🔴 Critical | `terraform/iam-roles-vulnerable.tf:32-65` | IAM role has AdministratorAccess policy attached |
| `OIDC_WILDCARD_ENVIRONMENT` | 🟠 High | `terraform/iam-roles-vulnerable.tf:67-100` | Trust policy uses `environment:*` allowing any environment |
| `OIDC_FORK_PR_RISK` | 🟠 High | `terraform/iam-roles-vulnerable.tf:102-135` | Trust policy allows `pull_request` event from forks |
| `OIDC_MISSING_AUD_CONDITION` | 🟡 Medium | `terraform/iam-roles-vulnerable.tf:137-170` | Trust policy missing `aud` condition validation |
| `AI_AGENT_OVERPRIVILEGED_ROLE` | 🔴 Critical | `terraform/bedrock-agent-misconfigured.tf` | Bedrock agent IAM role has `bedrock:*` and `s3:*` |
| `LAMBDA_EXECUTION_ROLE_ADMIN` | 🔴 Critical | `terraform/lambda-functions.tf` | Lambda execution role has AdministratorAccess |
| `LAMBDA_FUNCTION_URL_NO_AUTH` | 🟠 High | `terraform/lambda-functions.tf` | Function URL configured with `NONE` auth type |

**Control case**: `TrustFixDemo-Correct` role should NOT be flagged (or flagged as `VERIFIED`).

---

## Repository Structure

```
trustfix-demo/
├── README.md
├── LICENSE
├── .github/workflows/
│   ├── deploy-vulnerable.yml        # OIDC_MISSING_SUB_CONDITION
│   ├── deploy-overprivileged.yml    # OVERPRIVILEGED_ROLE
│   ├── deploy-wildcard-env.yml      # OIDC_WILDCARD_ENVIRONMENT
│   ├── deploy-fork-pr-risk.yml      # OIDC_FORK_PR_RISK
│   └── deploy-secure.yml            # Control: correctly configured
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── iam-oidc-provider.tf
│   ├── iam-roles-vulnerable.tf
│   ├── iam-roles-overprivileged.tf
│   ├── iam-trustfix-scanner.tf      # READ-ONLY scanner role
│   ├── bedrock-agent-misconfigured.tf
│   ├── s3-buckets.tf
│   └── lambda-functions.tf
├── docs/
│   ├── SETUP.md
│   ├── VULNERABILITIES.md
│   └── DEMO_SCRIPT.md
└── scripts/
    ├── deploy.sh
    └── destroy.sh
```

---

## Links

- **TrustFix Platform**: [https://trustfix.dev](https://trustfix.dev)
- **Documentation**: [https://docs.trustfix.dev](https://docs.trustfix.dev)
- **Security Policy**: [SECURITY.md](SECURITY.md)

---

## Disclaimer

This repository is provided **for demonstration purposes only**. The intentionally vulnerable configurations are designed to showcase TrustFix's detection capabilities.

- Do NOT use this infrastructure in production
- Deploy only to sandbox/demo AWS accounts
- Destroy infrastructure when not in use (`terraform destroy`)
- TrustFix and Vikavi Security LLC are not responsible for misuse

---

## License

MIT License — Copyright 2026 Vikavi Security LLC

See [LICENSE](LICENSE) for details.
