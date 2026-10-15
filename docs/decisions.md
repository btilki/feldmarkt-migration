# Feldmarkt migration decisions

**Status:** blueprint. These records lock the choices in [`scenario.md`](scenario.md) and [`requirements.md`](requirements.md). Nothing here has been applied to a cloud account. This is not an employer system.

Each record states the choice, why it won, and what it rules out for this wave.

## D1. Rehost `archiv` with **MGN** (**AWS Application Migration Service**)

**Choice.** `archiv` moves to **EC2** (**Elastic Compute Cloud**) in `eu-central-1` with MGN. The systemd service, the port `8443` listener, and the 40 GB disk at `/var/lib/feldmarkt` stay as they are.

**Why.** Two people use it. The value is the installed service and the disk. A container would be a rewrite of paths, the export job, and the service unit. MGN replicates the machine, gives a test instance before Sunday, and a cutover instance in the window.

**This wave does not.** Containerize `archiv`. Rebuild it by hand on a fresh EC2 image. Manage it with Ansible. The colo copy stays powered on through the seven-day hypercare window (RBK-2).

## D2. Replatform the `storefront` **JAR** (**Java Archive**) onto existing **EKS** (**Elastic Kubernetes Service**) **GitOps** (**Git operations**)

**Choice.** The same Spring Boot monolith moves to the existing EKS GitOps path. Pages and **API** (**application programming interface**) stay in one JAR. **CI** (**Continuous Integration**) publishes an image and opens a digest change. **Argo CD** (**Continuous Delivery**) deploys it. CI does not run `kubectl apply` or an Argo CD sync.

**Why.** The process stores no shop data on local disk. Today's pain is the shell script that copies the JAR onto the virtual machine. The paved road already exists: digest promotion through dev, then stage, then prod. Dev and stage prove the image against **RDS** (**Amazon Relational Database Service**) that holds non-production data. Production **DNS** (**Domain Name System**) stays on the colo until the Sunday proofs pass (TGT-4, TGT-5).

**This wave does not.** Build a new **VPC** (**Virtual Private Cloud**), a new EKS cluster, a new progressive-delivery stack, or a new observability stack.

## D3. Keep the Spring Boot monolith on its current version

**Choice.** The image runs the Spring Boot version recorded in the inventory. The JAR is not split.

**Why.** The colo contract is the deadline. A version upgrade and a microservice split each change application behavior during the same weekend as the infrastructure move. The migration proves the same monolith on a new runtime.

**Refused for this wave.**

| Path | Why it loses |
|------|----------------|
| Rewrite | New behavior, new defects, and a longer window than Sunday 02:00–06:00 **CET** (**Central European Time**). |
| Spring Boot upgrade | A framework change stacked on a runtime change. The inventory version and the image version must match (TGT-4). |
| Split into microservices | New boundaries and new failure modes while DNS and the database writer are also switching. |
| **SaaS** (**Software as a Service**) replacement | Replaces the shop instead of moving it. |
| Leave `storefront` in the colo | The colo contract is ending, and the release path stays a shell script. |
| Turn `storefront` off | The shop is still in use. |

## D4. Replatform PostgreSQL to RDS with **DMS** (**AWS Database Migration Service**)

**Choice.** The single PostgreSQL database on the `storefront` virtual machine moves to private RDS PostgreSQL with DMS. The major version and the schema stay the same. A schema-only copy, including indexes, foreign keys, defaults, and sequences, is applied to prod RDS before the task starts. The task uses `DO_NOTHING` for table preparation, full **LOB** (**Large Object**) mode, and row validation, so DMS loads rows into that schema instead of dropping and recreating tables. Replication uses the site-to-site **VPN** (**Virtual Private Network**) and is already running before Sunday. In the window, writes freeze, lag reaches zero, the row check passes, sequences are set from the colo, and only then does the manual prod sync start pods that write to RDS (TGT-6, TGT-7, CUT-4, PRF-5).

**Why.** The shop data lives in that database. Leaving it on the virtual machine keeps the colo in the production path after the JAR has moved. DMS is the continuous copy. A dump taken only inside the window would lengthen the freeze.

**This wave does not.** Add a second database. Change the engine. Rewrite the schema. Publish RDS on the internet (SEC-4). Put the database password in Git (SEC-3).

## D5. Site-to-site VPN for the move only

**Choice.** A site-to-site VPN from the Frankfurt colo to the existing VPC carries MGN replication, DMS replication, and the two archive users on private DNS. It stays up through the seven-day hypercare window. Wave 3 removes it. Wave 3 has no code in this repository.

**Why.** Both copies have to run while production is still in the colo. Two virtual machines do not justify a dedicated network circuit. After hypercare, the colo is no longer on the production path, so the site-to-site VPN has no remaining job. The two users then reach port 8443 by Systems Manager port forwarding. The instance stays private. That uses the instance profile from wave 1. It does not keep the VPN, and it does not publish the archive.

## D6. DNS switches callers, and the database writer switches first

**Choice.** DNS **TTL** (**Time to Live**) is lowered to 60 seconds before Sunday. Private DNS for `archiv` moves after the archive proofs. For `storefront`, the row check and sequence alignment come first. The manual prod sync then starts the pods against RDS. `GET /health` is taken from those pods. Public DNS moves only after that 200.

**Why.** Callers follow DNS. The new application must not start serving shoppers while it still writes to colo PostgreSQL, and it must not serve them until the row check has passed.

**Rollback.** `archiv` returns in 30 minutes by pointing private DNS back at the colo machine. `storefront` returns in 15 minutes by stopping the prod pods, stopping the DMS task, pointing DNS back at the colo VM, and reverting the Git digest pin. Stopping the pods is what ends writes to RDS. Stopping the task is what ends the copy from the colo onto that RDS. Database rollback points the application at colo PostgreSQL and recovers only rows from the write freeze. Rows written to RDS after the switch are not copied back (RBK-4).

## D7. This repository is the blueprint

**Choice.** The repository holds the scenario, the requirements, these decisions, the architecture, the cutover note, and the wave 1 and wave 2 code ready to apply. It does not apply them to a cloud account. It is not an employer system.

**Why.** The judgment is the path for each workload, the temporary network, the cutover order, and the rollback limit. Applying a stand-in colo would add account cost without changing those decisions.
