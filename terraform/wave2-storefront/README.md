# Wave 2 — `storefront` database path

Blueprint only. Do not apply this stack as part of writing the repository. It has not been applied to a cloud account.

| Resource | Job |
|----------|-----|
| **RDS** (**Amazon Relational Database Service**) `nonprod` | Private PostgreSQL for dev and stage. Its security group allows only the dev and stage pod group. Not a **DMS** (**AWS Database Migration Service**) target. |
| RDS `prod` | Private PostgreSQL. DMS target. Its security group allows only the prod pod group and DMS. Public access off. Deletion protection on. Minor upgrades off, so the engine version stays the colo major version. |
| DMS | Replication instance in the private subnets, source colo PostgreSQL, target prod RDS, full load plus **CDC** (**Change Data Capture**). Table preparation is `DO_NOTHING`. Full **LOB** (**Large Object**) mode. Row validation on. The task is created stopped. Apply the schema-only copy to prod RDS before starting it. |
| **ECR** (**Elastic Container Registry**) | Immutable repository for the storefront image. |

Passwords stay in Secrets Manager. External Secrets, already on the cluster, projects `nonprod_secret_arn` and `prod_secret_arn` into the Kubernetes secrets the chart reads. See [`gitops/secrets/`](../../gitops/secrets/). The colo secret **JSON** (**JavaScript Object Notation**) must contain `username` and `password`. This directory has no password. RDS rotates the managed master secret on its own schedule. After a rotation, roll the deployment once External Secrets has refreshed the Kubernetes secret.

The role `dms-vpc-role` is account-wide. An account that already has it cannot apply this stack until that existing role is the one DMS uses.

Dev and stage Helm values take `nonprod_endpoint`. The prod Helm value takes `prod_endpoint`. Sync prod after the row check and the sequence alignment. Take `GET /health` from those pods before public **DNS** (**Domain Name System**) moves. See [`gitops/README.md`](../../gitops/README.md).
