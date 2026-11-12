# Feldmarkt migration runbooks

> Status: Blueprint. These playbooks encode prep, freeze, proofs, post-move validation, and rollback checks for the Sunday window. Nothing here has been applied to a colo or a cloud account. This is not an employer system.

Decision: [D8](../docs/decisions.md). Ansible is migration automation. It does not rebuild `archiv`, does not replace MGN or DMS, and is not day-2 estate management for the cutover EC2 instance. After MGN launches that instance, `07-validate-archiv-cutover.yml` only asserts that the copy is healthy.

## Tools

| Pin | Role |
|-----|------|
| Ansible >= 2.15 | Run the playbooks from a control host that reaches the colo over the site-to-site VPN |
| AWS CLI v2 | Used by `03-preflight.yml` for MGN and DMS describes |
| `psql` | Client major version matches colo PostgreSQL |
| `ansible-vault` | Local secrets only; `vault.yml` is gitignored |

Copy [inventory/hosts.example.yml](inventory/hosts.example.yml) to `inventory/hosts.yml`. Copy [group_vars/all/vault.yml.example](group_vars/all/vault.yml.example) to `group_vars/all/vault.yml` when a password is required, then encrypt it.

```bash
cd ansible
cp inventory/hosts.example.yml inventory/hosts.yml
ansible-playbook playbooks/01-inventory.yml --check
```

## Playbooks

| Playbook | Requirement ids | Does | Does not |
|----------|-----------------|------|----------|
| [01-inventory.yml](playbooks/01-inventory.yml) | INV-1, INV-2, INV-3 | Gather OS, ports, units, Postgres version | Change config |
| [02-colo-prep.yml](playbooks/02-colo-prep.yml) | TGT-6, CUT-1 | Assert `wal_level=logical`, DMS role, TLS; remind DNS TTL | Rewrite DNS zones |
| [03-preflight.yml](playbooks/03-preflight.yml) | TGT-7, PRF-3 | Assert MGN source exists and DMS task is `running` | Start cutover or Argo sync |
| [04-cutover-freeze.yml](playbooks/04-cutover-freeze.yml) | CUT-3, CUT-4 | Stop units; set DB read-only when `-e confirm_freeze=true` | Flip DNS |
| [05-cutover-proofs.yml](playbooks/05-cutover-proofs.yml) | PRF-1, PRF-5 | Colo checksum; row-check and sequence SQL helpers | Prod health (kubectl); MGN launch; snapshot |
| [06-rollback-checks.yml](playbooks/06-rollback-checks.yml) | RBK-2, RBK-3, RBK-4 | Ping colo; optional `-e start_services=true` | Stop DMS; scale Argo; change DNS |
| [07-validate-archiv-cutover.yml](playbooks/07-validate-archiv-cutover.yml) | PRF-1, PRF-2 support | Check-only on the MGN cutover EC2: unit, port, disk, checksum print | Install packages; users; SSH; monitoring; DNS |

## After the move

Once MGN has launched the cutover instance, put its private IP in the `archiv_cutover` group in `inventory/hosts.yml`, then:

```bash
ansible-playbook playbooks/07-validate-archiv-cutover.yml
```

Compare that checksum to the colo result from `05-cutover-proofs.yml`. Private DNS still waits for the cutover note go line.

## Sunday map

Sunday order still follows [docs/cutover.md](../docs/cutover.md).

1. Before the window: `02-colo-prep.yml`, then `03-preflight.yml`
2. Freeze: `04-cutover-freeze.yml -e confirm_freeze=true`
3. Colo proof helpers: `05-cutover-proofs.yml`
4. After MGN cutover instance is up: `07-validate-archiv-cutover.yml` (before private DNS)
5. Rollback support: `06-rollback-checks.yml`

MGN start-cutover, the volume snapshot, Argo sync, pod health, and DNS changes stay outside Ansible.

## CI

[.github/workflows/ansible-lint.yml](../.github/workflows/ansible-lint.yml) runs syntax-check and `ansible-lint` on `ansible/**`. It does not reach a colo or AWS and does not run freeze.

## Frozen for these playbooks

- Rebuild `archiv` on a fresh AMI
- Ongoing config management of the cutover instance after wave 1 (users, SSH hardening, monitoring agents)
- Turning the colo off (wave 3 remains description only)
- AWX / Ansible Automation Platform
