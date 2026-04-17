# TrustFix Demo Script

**Duration**: 8-10 minutes

**Audience**: Prospects, investors, partners

**Setup required**: TrustFix demo environment deployed and connected to TrustFix platform

---

## Pre-Demo Checklist

- [ ] TrustFix dashboard loaded in browser
- [ ] Demo repo visible in connected repositories
- [ ] Demo AWS account visible in connected accounts
- [ ] Run a scan beforehand so findings are ready (optional — live scan works too)
- [ ] GitHub repo open in separate tab (to show Fix PRs)

---

## Demo Flow

### 1. Opening (30 seconds)

> "Welcome to TrustFix. I'm going to show you how our platform automatically discovers and remediates non-human identity vulnerabilities in your cloud environment."

> "What you're seeing is a real environment — not a slide deck. We've connected our demo GitHub repository and a sandbox AWS account."

### 2. Show Connections (1 minute)

Navigate to **Settings → Integrations**

> "TrustFix connects to your existing tools. Here we have GitHub connected — we're monitoring repositories for CI/CD workflows that use cloud credentials. And we have AWS connected — we're scanning IAM roles, policies, and trust relationships."

> "The magic is in correlating these two. We don't just look at GitHub OR AWS — we look at the relationship between them. That's where the real risks hide."

### 3. Trigger or View Scan (1 minute)

Navigate to **Dashboard**

Option A (pre-run scan):
> "I ran a scan earlier. Let's look at what TrustFix found."

Option B (live scan):
> "Let me kick off a scan right now." *Click New Scan, select repo + AWS, click Start*
> "This typically takes 2-3 minutes for a repo this size. In production, scans run continuously on every commit."

### 4. Review Findings Overview (2 minutes)

Show the findings dashboard with severity breakdown.

> "TrustFix found several critical vulnerabilities. Notice the severity distribution — we prioritize by actual blast radius, not just theoretical risk."

> "Let's start with the most dangerous one."

### 5. Deep Dive: OIDC Missing Sub Condition (2 minutes)

Click into the `OIDC_MISSING_SUB_CONDITION` finding.

> "This is a GitHub Actions workflow that assumes an AWS IAM role using OIDC — that's the modern, secure way to do it without storing long-lived credentials."

> "But there's a critical problem. The IAM role's trust policy accepts tokens from ANY GitHub repository. Not just this one — ANY repository in the world."

*Point to the trust policy snippet*

> "See this condition? It validates the audience but NOT the subject. The subject claim tells AWS which repo is requesting access."

> "An attacker could create their own GitHub repo, add a workflow, and assume this role. They'd get access to all S3 buckets this role can reach."

*Point to the blast radius section*

> "TrustFix shows the blast radius — this role has read access to production S3 buckets. That's the actual impact, not just a theoretical CVSS score."

### 6. Generate Fix (2 minutes)

> "Now here's what makes TrustFix different from a scanner. We don't just find problems — we fix them."

Click **Generate Fix**

> "TrustFix is now analyzing the workflow and the IAM role to generate a precise fix."

*Wait for PR to be created*

> "And there it is — a pull request in GitHub."

*Switch to GitHub tab, show the PR*

> "Look at this PR. TrustFix added the correct `sub` condition — it's scoped to this specific repository and the main branch. The workflow can still deploy, but no one else can abuse this role."

> "This isn't a generic recommendation. This is a working fix, ready to merge."

### 7. Show Trust Score Impact (1 minute)

Navigate back to dashboard, show Trust Score

> "See the Trust Score? Before the fix, we were at [X]. After merging that PR, we'll be at [Y]."

> "The Trust Score gives your security team — and your auditors — a single metric to track non-human identity hygiene over time."

### 8. Quick Tour of Other Findings (1 minute)

Scroll through other findings briefly.

> "We found several other issues too:
> - An overprivileged role with AdministratorAccess — no CI/CD workflow needs that
> - A wildcard environment condition — bypasses GitHub's environment protections
> - A Lambda function URL with no authentication
>
> Each of these has a one-click fix ready to go."

### 9. Closing (30 seconds)

> "Let me summarize what you just saw:
>
> 1. **Automatic discovery** — TrustFix found vulnerable identity configurations by correlating GitHub and AWS
> 2. **Blast radius analysis** — We show you the actual impact, not just the vulnerability
> 3. **One-click remediation** — Working pull requests, not just findings
> 4. **Trust Score** — Track your NHI security posture over time
>
> No other platform does this. We'd love to run this against your environment — it's a 15-minute setup. Do you have time to discuss next steps?"

---

## Handling Questions

### "How long does a scan take?"

> "Initial scans take 2-5 minutes depending on repo size. After that, we scan incrementally on every commit — typically under 30 seconds."

### "What if the fix breaks something?"

> "The PRs go through your normal review process. We also run validation against your existing workflows to ensure compatibility. You can preview the fix before merging."

### "Do you support other CI/CD platforms?"

> "Yes — we support GitHub Actions, GitLab CI, CircleCI, and Jenkins. AWS is our deepest integration, with Azure and GCP coming soon."

### "How is this different from AWS Access Analyzer?"

> "Access Analyzer is great for finding overly permissive policies. TrustFix goes further:
> 1. We correlate with CI/CD to understand actual usage patterns
> 2. We generate working fixes, not just findings
> 3. We track trust relationships across your entire stack"

### "What's the pricing?"

> "We price by number of non-human identities under management. For a typical enterprise, that's $X-Y per month. We're happy to do a scoped pilot to show value before committing."

---

## Demo Environment Reset

If you need to reset for another demo:

```bash
# Re-deploy vulnerable infrastructure
cd terraform
terraform destroy -auto-approve
terraform apply -auto-approve

# Close any Fix PRs in GitHub
gh pr list --state open --json number --jq '.[].number' | xargs -I {} gh pr close {}
```
