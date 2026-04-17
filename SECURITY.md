# Security Policy

## Reporting a Vulnerability

This is a demonstration repository containing INTENTIONALLY vulnerable configurations for demonstrating TrustFix's NHI security capabilities.

If you believe you've found a security issue that is NOT intentional (i.e., not documented in VULNERABILITIES.md), please report it:

- **Email**: security@trustfix.dev
- **Response time**: Within 48 hours
- **Scope**: Only non-intentional issues in this demo repository

## Intentional Vulnerabilities

This repository contains documented, intentional vulnerabilities used to demonstrate TrustFix. See [docs/VULNERABILITIES.md](docs/VULNERABILITIES.md) for the complete catalog. These are NOT security issues — they are educational examples.

## Safe Usage

To safely use this repository:

1. Deploy to a **DEDICATED sandbox AWS account**, never production
2. Use AWS Organizations to isolate the demo account
3. Destroy resources when not actively demonstrating (`terraform destroy`)
4. Do not expose the deployed resources to the public internet beyond what the demo requires
5. Monitor CloudTrail for unexpected access patterns

## TrustFix Platform Security

The TrustFix platform itself follows responsible disclosure and SOC 2 compliance. Platform security reports:

- **Email**: security@trustfix.dev
- **PGP Key**: Available at https://trustfix.dev/.well-known/security.txt

## License

MIT License — see [LICENSE](LICENSE) file.
