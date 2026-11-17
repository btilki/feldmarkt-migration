# Images

| File | Used in |
|------|---------|
| [feldmarkt-aws-migration-architecture-map.png](feldmarkt-aws-migration-architecture-map.png) | Root [README.md](../../README.md) — repository map and architecture |

Matches the repo story: `ansible/`, `charts/`, `gitops/`, `terraform/`, `app/`, `docs/` (decisions and cutover), `.github/workflows/`. GitOps notes manual sync for prod. Existing platform (observability, security) is labeled assumed. Footer states this is a blueprint.

## Map labels

| Map element | Meaning |
|-------------|---------|
| `app/` | Stand-in Spring Boot app (`Dockerfile`, JAR source). Kubernetes manifests live under `charts/` and `gitops/`. |
| Engineering domain — migration | AWS MGN (Application Migration Service), DMS (Database Migration Service), and Ansible cutover runbooks ([ansible/](../../ansible/)). |
| Assumed security (existing platform) | Secrets Manager and External Secrets Operator. |

On disk, paths are lowercase: `ansible/`, not `Ansible/`, and CI workflows live under `.github/workflows/` (leading dot). The PNG may shorten labels for layout; this table is authoritative.
