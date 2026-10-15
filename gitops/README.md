# Storefront **GitOps** (**Git operations**)

The cluster and **Argo CD** (**Continuous Delivery**) already exist. These files are the `storefront` application only.

| Path | Who changes it |
|------|----------------|
| `envs/dev/storefront.yaml` digest | **CI** (**Continuous Integration**), by pull request. CI does not deploy. |
| `envs/stage/storefront.yaml` digest | A reviewed promotion after dev is healthy. |
| `envs/prod/storefront.yaml` digest | A reviewed promotion. Argo CD does not auto-sync prod. |
| `database.host` | A person, from the wave 2 Terraform outputs. Dev and stage use the nonprod endpoint. Prod uses the **DMS** (**AWS Database Migration Service**) target. |

Sunday order for prod, from [`docs/cutover.md`](../docs/cutover.md):

1. DMS lag is zero and the row check matches.
2. Sequences on prod **RDS** (**Amazon Relational Database Service**) are set from the colo values.
3. Sync the prod Application. That sync is what starts the pods against prod RDS.
4. `GET /health` on those pods returns 200.
5. Public **DNS** (**Domain Name System**) moves. Until that go line, DNS stays on the colo.

The Kubernetes secrets `storefront-db-nonprod` and `storefront-db-prod` are projected by the External Secrets Operator already on the cluster, from the Secrets Manager **ARNs** (**Amazon Resource Names**) in the wave 2 outputs. The chart does not contain the password. Refresh is 15 minutes. RDS still rotates the managed master secret on its own schedule. If that version changes, roll the deployment after the Kubernetes secret has updated so the pods read the new password.

The prod Ingress joins the load balancer already on the cluster. `ingress.groupName` must be that load balancer's group. A new group name would create a second load balancer. Dev and stage leave the Ingress off.

The image digest in Git today is a placeholder of 64 zeros. It is not a published image. Replace `ACCOUNT` with the **ECR** (**Elastic Container Registry**) account before use.

Argo CD Applications point at `https://github.com/btilki/feldmarkt-migration.git`. Change that URL if the repository name differs.
