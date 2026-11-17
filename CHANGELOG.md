# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.2.3] — 2026-11-17

### Fixed

- Root README Proof: digest CI is push to `main` only, not pull request; ansible syntax-check covers every playbook.
- CONTRIBUTING: Ansible local checks match the ansible-lint workflow loop.

### Changed

- Root README: link to map label legend under architecture image.
- ROADMAP: optional L1 rehearsal capture guidance; L1 paragraph wording tightened.
- `docs/cutover.md`: optional L1 rehearsal labeling (prefix `Rehearsal —`, link to ROADMAP).

## [0.2.2] — 2026-11-17

### Fixed

- `docs/scenario.md`: storefront database row aligns RBK-4 recovery time and rollback columns.

### Changed

- `docs/lessons-learned.md`: impersonal voice aligned with the rest of the docs.
- `assets/images/README.md`: authoritative lowercase `ansible/` and `.github/workflows/` paths vs map shorthand.
- `ROADMAP.md`: roadmap phases vs migration waves called out.
- Root README: storefront digest workflow badge.
- `app/storefront/README.md`: version line without decorative bold.

## [0.2.1] — 2026-11-17

### Fixed

- `docs/scenario.md`: storefront application rollback matches RBK-3 (stop prod, stop DMS, DNS, digest pin).

### Changed

- Architecture map PNG: `app/` stand-in label, Ansible on migration domain, Secrets Manager and ESO on assumed platform.
- Architecture map legend in `assets/images/README.md`.
- Root README Proof: CI vs local checks in a table; GitHub Actions badge for ansible lint.
- `terraform/wave1-archiv/README.md`: MGN output described as values to copy into the replication template.
- `ansible/README.md`: DMS/MGN CLI wording; `implementation.md` Ansible row includes playbook `07`, step 7 and 11 skim splits.

## [0.2.0] — 2026-11-12

### Added

- Ansible migration runbooks (`01`–`07`): inventory, colo prep, preflight, freeze, proofs, rollback checks, post-MGN validate.
- GitHub Actions workflow for ansible-lint and playbook syntax-check.
- Architecture map image under `assets/images/`.
- Docs index, lessons-learned, and portfolio hygiene files (CONTRIBUTING, SECURITY, ROADMAP).

### Changed

- Root README reshaped to Problem / Decision / Result (Boutique-style), with honest blueprint proof.
- Docs style: short abbreviations only; less bold.
- Decisions use Choice / Why / Out of scope headings; long D4 and D8 paragraphs split for skimability.
- Architecture map set to `assets/images/feldmarkt-aws-migration-architecture-map.png`.

## [0.1.0] — 2026-10-15

Initial public blueprint on [btilki/feldmarkt-migration](https://github.com/btilki/feldmarkt-migration).

### Added

- Scenario, requirements, decisions, architecture, cutover note, implementation guide.
- Terraform wave 1 (`archiv` landing shape for MGN) and wave 2 (private RDS, stopped DMS task, ECR).
- Storefront stand-in (Spring Boot 3.5.5), Helm chart, GitOps pins, External Secrets manifests.
- GitHub Actions digest pull request for dev only (CI never deploys).
