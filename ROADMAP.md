# Roadmap — feldmarkt-migration

Vision: A defendable colo → AWS migration blueprint. Rehost with MGN, replatform Spring Boot and PostgreSQL onto an existing EKS GitOps path, with Ansible as migration runbooks only.

Status: Blueprint encoded. Not applied to a cloud account.

---

## Phase overview

| Phase | Title | Status |
|-------|--------|--------|
| 0 | Scenario, requirements, decisions, architecture, cutover note | Done |
| 1 | Wave 1 Terraform — archiv landing shape | Done |
| 2 | Wave 2 Terraform — RDS, DMS stopped, ECR | Done |
| 3 | Chart, GitOps pins, External Secrets, digest CI | Done |
| 4 | Implementation guide | Done |
| 5 | Ansible migration runbooks + lint CI + post-move validate | Done |
| 6 | Portfolio docs (README reshape, hygiene files, lessons) | Done |
| 7 | Lived apply in a throwaway account (optional) | Not started |
| 8 | Wave 3 — remove colo and VPN | Described only; no code by design |

Status words: Not started · In progress · Done · Described only

---

## Milestones

| Milestone | Definition of done |
|-----------|--------------------|
| B1 — Blueprint readable | README Problem/Decision/Result; docs index; decisions D1–D8 |
| B2 — Code ready to apply | Wave 1/2 validate; helm template; ansible-lint green |
| B3 — Portfolio hygiene | CONTRIBUTING, SECURITY, CHANGELOG, ROADMAP, lessons-learned |
| L1 — Lived rehearsal (optional) | Apply in a throwaway account; fill cutover note once; tear down |

B1–B3 are the portfolio finish line. L1 is optional and must stay labeled as a rehearsal, not an employer system.

---

## Explicitly out of scope

- Day-2 Ansible estate management for the cutover EC2
- New VPC / EKS / observability / progressive-delivery stack in this repo
- Spring Boot upgrade, microservices split, engine or schema rewrite
- .NET twin that only swaps the language

---

## Related

- [README.md](README.md)
- [docs/lessons-learned.md](docs/lessons-learned.md)
- [docs/decisions.md](docs/decisions.md)
