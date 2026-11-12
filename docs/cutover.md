# Feldmarkt cutover note

> Status: Blueprint template. The operator fills the blank lines during a real window. Nothing here has been applied to a cloud account. This is not an employer system.

Sunday 02:00–06:00 CET. DNS is the switch for callers. The database writer switches before public DNS for `storefront`. A failed proof stops that workload and leaves its DNS on the Frankfurt colo (CUT-5).

Decisions: [D6](decisions.md), [D8](decisions.md). Order: [architecture §3](architecture.md). Ansible runbooks: [ansible/README.md](../ansible/README.md).

## Before the window

Record these before Sunday 02:00 CET. A blank line means the window does not start. Run `ansible-playbook playbooks/02-colo-prep.yml` and `playbooks/03-preflight.yml` from [ansible/](../ansible/) before filling the AWS and colo rows.

| Check | Record |
|-------|--------|
| DNS TTL for the private `archiv` record and the public `storefront` record is 60 seconds (CUT-1) | Changed at: |
| MGN test instance booted and served port 8443 (PRF-3) | Date: |
| DMS task is running over the VPN into the private production RDS (TGT-7) | Task: |
| Schema-only copy is already on prod RDS: tables, indexes, foreign keys, defaults, and sequences. DMS table preparation is `DO_NOTHING` | Applied at: |
| `storefront` dev `GET /health` returned 200 on its digest, against non-production RDS (PRF-4) | Digest: |
| `storefront` stage `GET /health` returned 200 on its digest, against non-production RDS (PRF-4) | Digest: |
| Colo virtual machines are powered on | Confirmed at: |
| Ansible `03-preflight.yml` passed | At: |

Dev and stage do not use the RDS instance that receives the production DMS copy.

## Sunday, in order

### 1. Freeze

Use `ansible-playbook playbooks/04-cutover-freeze.yml -e confirm_freeze=true` from [ansible/](../ansible/), or stop the units by hand. Record both times.

| Event | Time |
|-------|------|
| Writes stop on `archiv` | |
| Writes stop on `storefront`, including colo PostgreSQL | |

Both times must fall inside 02:00–06:00 CET (CUT-3, CUT-4).

### 2. `archiv` proofs

| Event | Record |
|-------|--------|
| MGN final sync finished | |
| Checksum of `/var/lib/feldmarkt` on the colo disk at freeze (`05-cutover-proofs.yml` helps) | |
| Checksum of `/var/lib/feldmarkt` on the cutover instance (`07-validate-archiv-cutover.yml` helps) | |
| Equal (PRF-1) | yes / no |
| One archive export on the cutover instance | success / fail, at |
| Snapshot of the cutover data volume, taken before DNS (CUT-6) | Snapshot id: |

**Go, private DNS.** Written only after both checksums are equal, the export succeeded, and the snapshot id is filled.

```text
GO archiv  time:
private DNS target: EC2 cutover instance
previous target remains: colo archiv
```

**No-go.** Any failed proof. Private DNS stays on the colo. Record the failed check. Do not start a second attempt inside this window.

```text
NO-GO archiv  time:
failed check:
DNS record unchanged: yes
```

### 3. `storefront` proofs

The row check finishes before sequences are aligned. The manual prod sync starts the pods. The health check is taken from those pods (CUT-4, PRF-4, PRF-5).

| Event | Record |
|-------|--------|
| DMS lag reached zero | |
| Row check, colo PostgreSQL | |
| Row check, RDS | |
| Equal (PRF-5) | yes / no |
| Sequences on RDS set from the colo values | |
| Prod Application synced | |
| Production digest | |
| RDS endpoint that digest uses | |
| `GET /health` on port 8080 returned 200 from those pods (PRF-4) | yes / no, at |

**Go, public DNS.** Written only after lag zero, equal row checks, sequence alignment, the prod sync, and a 200 from those pods.

```text
GO storefront  time:
writer: RDS
public DNS target: existing load balancer
previous target remains: colo storefront
```

**No-go.** Lag did not reach zero, the row checks differ, sequences were not aligned, the prod sync did not become healthy, or health was not 200. Public DNS stays on the colo. If the prod Application was synced, scale it to 0 and stop the DMS task before leaving the window. Rows those pods wrote to RDS are not on the colo. Production writes stay on colo PostgreSQL.

```text
NO-GO storefront  time:
failed check:
DNS record unchanged: yes
production writer remains: colo PostgreSQL
```

The two workloads are separate. A no-go for one does not undo a go already recorded for the other. Rollback of a recorded go uses the steps below.

## Rollback

Times start when the rollback decision is made. The colo machines stay powered on. `ansible-playbook playbooks/06-rollback-checks.yml -e start_services=true` verifies the colo can accept traffic again; it does not flip DNS or stop DMS.

**`archiv`, 30 minutes (RBK-2).**

1. Point private DNS back at the colo machine.
2. Stop the EC2 cutover instance and keep it.
3. Leave the volume snapshot in place.

```text
ROLLBACK archiv  decided at:
DNS pointed at colo at:
EC2 stopped at:
```

**`storefront` application, 15 minutes (RBK-3).** Do these in order. The first two steps are what stop writes.

1. Scale the prod Application to 0 replicas. The pods must be gone before DNS moves.
2. Stop the DMS replication task.
3. Point public DNS back at the colo virtual machine.
4. Revert the Git digest pin. Do not sync prod again in this window.

```text
ROLLBACK storefront app  decided at:
prod replicas at 0 at:
DMS task stopped at:
DNS pointed at colo at:
digest pin reverted at:
```

**`storefront` database (RBK-4).**

1. Point the application at colo PostgreSQL.
2. Treat rows written to RDS after the go line as outside the recovery point. They are not copied back.

```text
ROLLBACK storefront database  decided at:
application writer set to colo PostgreSQL at:
post-switch RDS writes are not recovered: acknowledged
```

## Seven days

Hypercare starts at the later of the two go times, or at the only go time if one workload was a no-go.

| Line | Record |
|------|--------|
| Hypercare starts | |
| Hypercare ends (start plus seven days) | |
| Production writer during these seven days | RDS, if storefront went |
| Colo machines, colo PostgreSQL, and the VPN | stay on |
| If the prod secret version changes, roll prod after External Secrets has updated `storefront-db-prod` | |

During these seven days, callers who were switched use AWS. The colo stays powered on so the rollback steps above still work. Callers are not sent to both sides.

Wave 3, removing the VPN and the colo, is not a step in this note. It waits until the end time above has passed with no open rollback.
