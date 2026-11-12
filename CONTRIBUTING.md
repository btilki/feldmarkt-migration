# Contributing — feldmarkt-migration

Audience: engineers opening pull requests on this blueprint repository.  
Authority: [docs/decisions.md](docs/decisions.md) and [docs/requirements.md](docs/requirements.md) win if chat, README, or scripts disagree.

## Rules

1. One bounded change per PR — do not mix unrelated Terraform, Ansible, and chart edits without a clear reason.
2. Digest promotion for stage and prod is a reviewed Git change. CI may edit only `gitops/envs/dev/storefront.yaml`.
3. CI must not deploy — no `kubectl` or `argocd` in GitHub Actions ([`.github/workflows/storefront-digest.yml`](.github/workflows/storefront-digest.yml)).
4. Never commit secrets — no AWS keys, `terraform.tfvars`, Ansible `vault.yml`, or live passwords. Use examples and placeholders.
5. Ansible stays migration runbooks ([D8](docs/decisions.md)). Do not add day-2 estate management roles (users, SSH hardening, monitoring agents) without reopening D1.
6. Keep the status honest: this is a blueprint. Do not claim a lived cutover or an employer system.
7. Prefer short abbreviations in docs. Do not expand every acronym in parentheses.

## Local checks before push

```bash
# Terraform (from each wave directory after terraform init)
terraform validate

# Stand-in app
mvn -B -ntp -f app/storefront/pom.xml verify

# Chart render
helm template storefront charts/storefront -f gitops/envs/prod/storefront.yaml

# Ansible
cd ansible && ansible-playbook --syntax-check -i inventory/hosts.example.yml playbooks/01-inventory.yml
cd ansible && ansible-lint
```

## Where to start

| Goal | Start here |
|------|------------|
| Understand the design | [README.md](README.md) · [docs/scenario.md](docs/scenario.md) |
| Decisions | [docs/decisions.md](docs/decisions.md) |
| Operator order | [docs/implementation.md](docs/implementation.md) |
| Cutover template | [docs/cutover.md](docs/cutover.md) |
| Ansible runbooks | [ansible/README.md](ansible/README.md) |

## Security reports

See [SECURITY.md](SECURITY.md).

## License

Contributions are under the [Apache License 2.0](LICENSE) (Copyright 2026 Birol Tilki), unless noted otherwise.
