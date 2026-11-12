# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
