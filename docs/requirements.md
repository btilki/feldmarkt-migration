# Feldmarkt migration requirements

**Status:** blueprint. These are the yes-or-no checks for the move in [`scenario.md`](scenario.md). Nothing here has been applied to a cloud account. This is not an employer system.

A requirement is met only when the proof in its row is true. A failed proof stops that wave and leaves **DNS** (**Domain Name System**) for that workload pointing at the Frankfurt colo.

## 1. Inventory

What exists today, before anything moves.

| ID | Requirement | Proof |
|----|-------------|-------|
| INV-1 | `archiv` is one Ubuntu virtual machine in the Frankfurt colo. A systemd service listens on port 8443. A 40 GB data disk is mounted at `/var/lib/feldmarkt`. Two people use it. | Inventory row lists hostname, **OS** (**operating system**), port, disk path, disk size, and the two users. |
| INV-2 | `storefront` is one Ubuntu virtual machine in the same colo. One Spring Boot monolith serves pages and the **API** (**application programming interface**) from a single **JAR** (**Java Archive**) on port 8080. A shell script copies that JAR onto the machine. The process stores no shop data on local disk. | Inventory row lists hostname, OS, port, the JAR name, the Spring Boot version, and the script path used for today's release. |
| INV-3 | PostgreSQL runs on the `storefront` virtual machine. It is the only database in this wave. The schema belongs to `storefront`. | Inventory row lists the engine, the major version, the database name, and that it listens only on the colo machine. |

## 2. Target

Where each workload lands. The **VPC** (**Virtual Private Cloud**) and the **EKS** (**Elastic Kubernetes Service**) **GitOps** (**Git operations**) platform already exist. This repository does not create them.

| ID | Requirement | Proof |
|----|-------------|-------|
| TGT-1 | `archiv` is rehosted to **EC2** (**Elastic Compute Cloud**) in `eu-central-1` with **MGN** (**AWS Application Migration Service**). The installed service and the disk stay as they are. | Wave 1 describes an MGN source, continuous replication, a test instance, and a cutover instance. |
| TGT-2 | The MGN agent on `archiv` replicates over a site-to-site **VPN** (**Virtual Private Network**) from the colo to the existing VPC. The VPN exists for the move and for the seven-day hypercare window. | A network note shows the VPN up before replication starts and still up during the seven days. |
| TGT-3 | The cutover instance for `archiv` runs in a private subnet. | Subnet and route for the cutover instance have no public address. |
| TGT-4 | The `storefront` JAR is replatformed onto the existing EKS GitOps path on the same Spring Boot version. **CI** (**Continuous Integration**) publishes an image and opens a digest change. **Argo CD** (**Continuous Delivery**) deploys that digest. CI does not deploy. | Wave 2 shows a digest pin per environment and a pipeline with no `kubectl apply` and no Argo CD sync. The image manifest names the same Spring Boot version as INV-2. |
| TGT-5 | `storefront` is promoted dev, then stage, then prod. Dev and stage use **RDS** (**Amazon Relational Database Service**) with non-production data. Production DNS and production writes stay on the colo until the Sunday window. | Dev and stage are healthy before the window. The prod DNS record still names the colo **VM** (**virtual machine**) until cutover. |
| TGT-6 | PostgreSQL is replatformed to RDS PostgreSQL in `eu-central-1` with **DMS** (**AWS Database Migration Service**). The major version and the schema stay the same. | Wave 2 describes a DMS source, an RDS target of the same major version, table preparation `DO_NOTHING`, full **LOB** (**Large Object**) mode, and row validation. A schema-only copy is on prod RDS before the task starts. |
| TGT-7 | DMS replicates over the same site-to-site VPN. Replication is already running before the Sunday window. | The replication task is recorded as running before Sunday 02:00 **CET** (**Central European Time**). |

## 3. Cutover

Sunday 02:00–06:00 CET. DNS is the switch for callers. The database writer switches before public DNS for `storefront`.

| ID | Requirement | Proof |
|----|-------------|-------|
| CUT-1 | DNS **TTL** (**Time to Live**) for both records is lowered to 60 seconds before the window. | The TTL change is recorded before Sunday 02:00 CET. |
| CUT-2 | Private DNS for `archiv` changes only after the archive proofs pass. Public DNS for `storefront` changes only after the application proof and the database proof pass. | The cutover note has a go line for each record, written after the proof, before the DNS change. |
| CUT-3 | Writes on `archiv` freeze at the start of the window. MGN completes a final sync before the checksum. | Freeze start time and final-sync finish time are both inside the window. |
| CUT-4 | Writes on `storefront` freeze at the start of the window. DMS lag reaches zero before the row check. Production on EKS writes to RDS only after that check. | Freeze start time, lag-zero time, and the RDS endpoint used by the production digest are recorded inside the window, in that order. |
| CUT-5 | A failed proof stops that workload. DNS for that workload stays on the colo. | The cutover note records the failed check and shows the DNS record unchanged. |
| CUT-6 | The data volume on the `archiv` cutover instance is snapshotted before private DNS for `archiv` changes. | Snapshot id is recorded before the DNS change. |

## 4. Rollback

The colo stays available. Recovery times below are from the moment the decision to roll back is made.

| ID | Requirement | Proof |
|----|-------------|-------|
| RBK-1 | Recovery point for `archiv` is the write freeze. Data written before the freeze is on the cutover instance. | Checksum of `/var/lib/feldmarkt` on the cutover instance matches the colo disk at freeze. |
| RBK-2 | Recovery time for `archiv` is 30 minutes: point private DNS back at the colo machine. | Rollback step is a single DNS change to the colo address. Colo VM is still powered on. |
| RBK-3 | The `storefront` process has no shop data on local disk. Recovery time is 15 minutes. Prod pods are stopped, the DMS task is stopped, public DNS points back at the colo VM, and the Git digest pin is reverted. | The rollback lists those four actions in that order. |
| RBK-4 | Recovery point for the `storefront` database is the write freeze. Rollback points the application at colo PostgreSQL. Rows written to RDS after the switch are not copied back. | The rollback note states the colo database as the target and states that post-switch RDS writes are outside the recovery point. |
| RBK-5 | After a successful cutover, the colo machines, colo PostgreSQL, and the VPN stay for seven days. RDS is the production writer during those seven days. | Hypercare end time is cutover time plus seven days. Wave 3 is not part of this window. |

## 5. Proof

The proofs for a workload are required before DNS for that workload changes.

| ID | Requirement | Proof |
|----|-------------|-------|
| PRF-1 | The checksum of `/var/lib/feldmarkt` matches between the colo disk at freeze and the cutover instance. | Two checksum values are written in the cutover note and they are equal. |
| PRF-2 | One archive export succeeds on the cutover instance before DNS changes. | Export finish time and a success result are recorded inside the window. |
| PRF-3 | Before the window, an MGN test instance for `archiv` has already booted and served port 8443. | Test-instance check is dated before Sunday. |
| PRF-4 | `GET /health` on `storefront` port 8080 returns 200 from the digest that production will run. Dev and stage already passed this check before the window. The production check is taken after the manual prod sync, from pods that use prod RDS. | Health result, digest, database endpoint, and environment are recorded for dev, stage, and the synced prod pods. |
| PRF-5 | At lag zero, a row check of the `storefront` schema matches between colo PostgreSQL and RDS. | Two row-check results are written in the cutover note and they are equal. |

## 6. Security

| ID | Requirement | Proof |
|----|-------------|-------|
| SEC-1 | Operators reach the `archiv` instance with Systems Manager. The security group has no inbound **SSH** (**Secure Shell**) from the internet. | No rule allows `0.0.0.0/0` on port 22. The access note names Systems Manager. |
| SEC-2 | `archiv` is not published on the public internet. During the move and the seven days, the two users use the private DNS name over the site-to-site VPN. After wave 3 they use Systems Manager port forwarding to port 8443. | No public address and no public listener on port 8443. The wave 3 path names Systems Manager. |
| SEC-3 | Git holds no secrets, credentials, or database passwords. External Secrets, already on the cluster, projects the Secrets Manager **ARN** (**Amazon Resource Name**) into the Kubernetes secret the chart reads. | An ExternalSecret names that ARN. No password is committed. |
| SEC-4 | RDS has no public endpoint. DMS and the allowed pod security groups reach it through private networking. | `publicly_accessible` is false, and no security group allows `0.0.0.0/0` on 5432. |
| SEC-5 | Nonprod RDS accepts PostgreSQL only from the dev and stage pod security group. Prod RDS accepts PostgreSQL only from the prod pod security group and from DMS. Those two pod security groups are different, and neither is the shared node group. | The two ingress rules name different security group ids. |

## Frozen

These stay out of the repository, as in the scenario: a second database, a different database engine, a schema rewrite, a Spring Boot upgrade, a split into microservices, VMware tooling, a new VPC or EKS cluster, a new progressive-delivery or observability stack, Ansible for the estate, a second region, and code that turns the colo off.
