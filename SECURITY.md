# Security — feldmarkt-migration

Audience: engineers reviewing or later applying this blueprint.  
Related: [docs/requirements.md](docs/requirements.md) (SEC-1…SEC-5) · [docs/decisions.md](docs/decisions.md)

## Principles

| Principle | How this blueprint applies it |
|-----------|-------------------------------|
| Least privilege | CI role pushes to ECR only. Prod Argo sync is manual. No cluster deploy from CI. |
| Secrets hygiene | RDS master secrets in Secrets Manager; External Secrets projects them. Never commit passwords or `vault.yml`. |
| Private by default | Archiv cutover instance has no public IP. RDS `publicly_accessible=false`. Operators use Systems Manager. |
| Separate blast radius | Nonprod and prod RDS use different pod security groups. Neither is the shared node group. |
| Migration automation | Ansible asserts and freezes; it does not rewrite SSH or open the archive to the internet. |

## Trust boundaries (summary)

1. Human + Git — change desired state via pull request  
2. Argo CD — reconciler for storefront on the existing cluster  
3. AWS account — VPC, EKS, RDS, DMS, MGN, ECR (landing zone assumed; this repo does not create the VPC/EKS)  
4. Colo — source of truth until Sunday DNS; stays on for seven-day hypercare  

## Reporting

If you find a vulnerability in this repository’s configs or docs, contact the owner ([@btilki](https://github.com/btilki)). Do not open a public issue with exploit details against a live account.

## Honest limits

- This is a blueprint. Nothing here has been applied to a cloud account from this repository.
- `ACCOUNT`, certificate ARNs, digests of 64 zeros, and `REPLACE_WITH_*` values are placeholders.
- The storefront under `app/storefront/` is a stand-in health contract, not the colo shop.
- Site-to-site VPN is required for the move and is not Terraform in this repo.
- Wave 3 (remove colo and VPN) has no code.
