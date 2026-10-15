# Feldmarkt implementation guide

**Status:** blueprint. These are the tools and the order an operator would use. Nothing in this repository has been applied to a cloud account. This is not an employer system.

Read [scenario.md](scenario.md), [decisions.md](decisions.md), and [cutover.md](cutover.md) before the first command. This guide says which tool runs each step. The cutover note is where the Sunday results are written.

## Tools

| Tool | Pin | Does | Does not |
|------|-----|------|----------|
| Terraform | >= 1.9, **AWS** (**Amazon Web Services**) provider ~> 6.0 | Apply [wave 1](../terraform/wave1-archiv/) and [wave 2](../terraform/wave2-storefront/) | Launch the `archiv` machine. Deploy `storefront`. |
| AWS **CLI** (**command line interface**) | v2 | **MGN** (**AWS Application Migration Service**) settings, **DMS** (**AWS Database Migration Service**) start and stop, the volume snapshot, Systems Manager, **DNS** (**Domain Name System**) **TTL** (**Time to Live**) | Deploy to the cluster |
| Session Manager plugin | current | Operator shell on `archiv`. After wave 3, the two users reach port 8443 through it | Replace private DNS during the seven days |
| Helm | 3 | Render the chart and read the manifest | Apply the chart. **Argo CD** (**Continuous Delivery**) is the deployer |
| Argo CD CLI | v2, already on the cluster | Manual prod sync. Scale prod to 0 on rollback | Run inside **CI** (**Continuous Integration**) |
| Docker | current | Build the stand-in image. CI does this | Deploy |
| Git | current | Digest pins. CI opens a pull request for dev only | |
| psql | client major version = colo PostgreSQL | Schema-only load, row check, sequence alignment | |
| python3 | 3 | The digest pin in CI | |

`kubectl apply` and `argocd app sync` from CI are forbidden. An operator applies the Application and ExternalSecret manifests once, in step 7, and may use `kubectl port-forward` to read `GET /health`. Sync and scale go through the Argo CD CLI.

## Already on the landing zone

This repository does not create these. The steps below fail closed when one is missing.

- **VPC** (**Virtual Private Cloud**) and at least two private subnets in `eu-central-1`
- A private path for **TCP** (**Transmission Control Protocol**) 443 from those subnets to the MGN and DMS **APIs** (**application programming interfaces**)
- **EKS** (**Elastic Kubernetes Service**), Argo CD, the AWS Load Balancer Controller, and one existing **ALB** (**Application Load Balancer**) group name
- The certificate on that load balancer
- ClusterSecretStore named `aws-secrets`
- Two different pod security groups: one for dev and stage, one for prod. Neither is the shared node group
- The Frankfurt colo, with a public **IP** (**Internet Protocol**) address for the customer gateway

## 1. Fill the placeholders

Do not commit live passwords or account secrets. Endpoints and secret **ARNs** (**Amazon Resource Names**) do not exist until wave 2 has been applied, so this step is split.

Before any apply:

| Placeholder | Where |
|-------------|--------|
| `ACCOUNT` | Chart defaults, and [dev](../gitops/envs/dev/storefront.yaml), [stage](../gitops/envs/stage/storefront.yaml), and [prod](../gitops/envs/prod/storefront.yaml) |
| `REPLACE_WITH_EXISTING_ALB_GROUP`, `REPLACE_WITH_EXISTING_CERTIFICATE_ARN` | Prod env file and the chart defaults |
| `shop.example.invalid` | Prod Ingress host, in the prod env file and the chart defaults. Replace it with the public shop name |
| `REPLACE_WITH_RDS_ENDPOINT` | Chart default database host. Each env file overrides it after wave 2. Replace the chart default as well, so a render without an env file does not keep the placeholder |
| `https://github.com/btilki/feldmarkt-migration.git` | The three Argo CD Applications, if the repository name differs |
| Terraform variables | `terraform.tfvars` copied from each `terraform.tfvars.example` |

`archive_clients_cidr` during the move is the colo **CIDR** (**Classless Inter-Domain Routing**) range, because the two users arrive over the **VPN** (**Virtual Private Network**). It cannot be `0.0.0.0/0`.

After wave 2 apply, from the Terraform outputs:

| Output | Where |
|--------|--------|
| `nonprod_endpoint` | `REPLACE_WITH_NONPROD_ENDPOINT` in the dev and stage env files |
| `prod_endpoint` | `REPLACE_WITH_PROD_ENDPOINT` in the prod env file |
| `nonprod_secret_arn`, `prod_secret_arn` | [gitops/secrets/](../gitops/secrets/) |
| `ecr_repository_url` | Repository variable `ECR_REPOSITORY` in step 7 |

## 2. Site-to-site VPN

Tool: AWS CLI. This repository has no Terraform for the VPN.

Create a customer gateway with the colo public IP, a virtual private gateway on the existing VPC, and a site-to-site VPN with static routes. Route the colo CIDR into the VPC, and the VPC CIDR back to the colo. The tunnel carries MGN replication, DMS replication, and the two archive users.

Leave this VPN up through the seven-day hypercare window. Wave 3 deletes it.

## 3. Wave 1, the `archiv` landing shape

Tool: Terraform, from [terraform/wave1-archiv](../terraform/wave1-archiv/).

```bash
terraform init
terraform plan
terraform apply
```

This creates the private security groups, the Systems Manager instance profile, and a launch template with no **AMI** (**Amazon Machine Image**). It does not start an instance.

Copy `mgn_replication_settings` into the MGN replication template in the account: private subnet, the replication security group, `create_public_ip` false, `PRIVATE_IP` routing. MGN creates its own launch template per source server. Copy these fields into that template. Do not tell MGN to launch our template id.

- Subnet: the private subnet
- Security group: `cutover_security_group_id`
- Instance profile: `instance_profile_name`
- Public IP: off
- IMDSv2: required

## 4. Replicate `archiv`

Tool: AWS replication agent on the colo virtual machine, then the AWS CLI.

Install the agent on `archiv`. Replication uses TCP 1500 from the colo CIDR to the replication servers, over the VPN. Start a test instance before Sunday.

```bash
aws mgn start-test --source-server-ids "$SOURCE_SERVER_ID"
```

Record the date that test instance served port 8443 in [cutover.md](cutover.md) (PRF-3). The test instance is not the Sunday machine. MGN launches a separate cutover instance in step 9.

## 5. Wave 2, the database and the registry

Tool: Terraform, from [terraform/wave2-storefront](../terraform/wave2-storefront/).

```bash
terraform init
terraform plan
terraform apply
```

This creates nonprod **RDS** (**Amazon Relational Database Service**), prod RDS, a stopped DMS task, and the immutable **ECR** (**Elastic Container Registry**) repository. Prod RDS accepts PostgreSQL only from the prod pod security group and from DMS. Nonprod accepts it only from the dev and stage pod security group.

Write the four outputs from the step 1 table into Git and into `ECR_REPOSITORY`. Commit the Git values. Do not commit a password.

## 6. Schema, then start DMS

Tool: `pg_dump` and `psql` over the VPN, then the AWS CLI.

On the colo database, before the task is started:

```bash
pg_dump --schema-only --no-owner --schema=public "$COLO_URL" | psql "$PROD_RDS_URL"
```

That load is the tables, indexes, foreign keys, defaults, and sequences. The DMS task is `DO_NOTHING`, so it will not drop them.

Then start the task. It stays running until a no-go or a rollback stops it.

```bash
aws dms start-replication-task \
  --replication-task-arn "$TASK_ARN" \
  --start-replication-task-type start-replication
```

Record the task id in the cutover note (TGT-7). Dev and stage never use this RDS instance.

## 7. `storefront` on dev, then stage

Tool: GitHub Actions for the image, `kubectl` once to register the manifests, Argo CD for the deploy.

The digest job stays off until both repository variables are set. `ECR_REPOSITORY` is the wave 2 output `ecr_repository_url`. `AWS_ROLE_ARN` is an existing GitHub **OIDC** (**OpenID Connect**) role that can push to that repository. This repository does not create that role.

```bash
gh variable set AWS_ROLE_ARN --body "$AWS_ROLE_ARN"
gh variable set ECR_REPOSITORY --body "$ECR_REPOSITORY"
```

Push to `main` under `app/storefront/`. The workflow tests, pushes an immutable image, and opens a pull request that changes only `gitops/envs/dev/storefront.yaml`. The pin is the `sha256:` value from the push, 64 hex characters. Merge that pull request.

Nothing in this repository registers the Applications or the ExternalSecrets on the cluster. After the dev digest on `main` is that published value, create the namespaces, apply the secrets, then register dev:

```bash
kubectl create namespace storefront-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace storefront-stage --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace storefront-prod --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f gitops/secrets/storefront-nonprod.yaml
kubectl apply -f gitops/secrets/storefront-prod.yaml
kubectl apply -f gitops/apps/storefront-dev.yaml
```

`storefront-dev` then syncs from Git. Apply `storefront-stage` only after a reviewed commit has put that same digest in the stage env file. Apply `storefront-prod` after its placeholders are filled. Prod has no automated sync, so that apply does not start pods.

```bash
kubectl apply -f gitops/apps/storefront-stage.yaml
kubectl apply -f gitops/apps/storefront-prod.yaml
```

Do not let CI edit stage or prod.

Prove dev and stage with a read-only check. `GET /health` on port 8080 returns 200. Both use the nonprod endpoint. The image has no shell tools, so the check is a port forward from the operator machine.

```bash
kubectl port-forward -n storefront-dev deploy/storefront 8080:8080
curl -fsS http://127.0.0.1:8080/health
```

Prod stays unsynced. Its Ingress is in Git and joins the existing ALB group only when that Application is synced.

## 8. Sunday, before 02:00 **CET** (**Central European Time**)

Tool: AWS CLI for DNS. The cutover note is the record.

Lower both DNS records to TTL 60. Confirm the MGN test, the running DMS task, the schema-only load, and the dev and stage health checks. The colo machines stay powered on.

## 9. Sunday window

Fill [cutover.md](cutover.md) while you do this. A failed proof stops that workload and leaves its DNS on the colo.

**Freeze, at 02:00 CET.** On the colo, stop the `storefront` systemd unit, set the database read-only, and stop the `archiv` systemd unit.

```sql
ALTER DATABASE storefront SET default_transaction_read_only = on;
```

**`archiv`.** Start the MGN cutover. That launches the cutover instance and runs the final sync. The test instance from step 4 stays a test.

```bash
aws mgn start-cutover --source-server-ids "$SOURCE_SERVER_ID"
```

Wait until the final sync has finished and the cutover instance is running. Checksum the colo disk and the disk on that cutover instance:

```bash
tar -C /var/lib/feldmarkt -cf - . | sha256sum
```

Run one archive export on the cutover instance. Snapshot that instance's data volume:

```bash
aws ec2 create-snapshot --volume-id "$VOLUME_ID" --description "feldmarkt-archiv-before-dns"
```

Write the go line, then change the private DNS record to the cutover instance. On a failed proof, write the no-go line and do not change DNS.

**`storefront`.** Wait until DMS lag is zero. Build the row-check statement on either side, then run that same statement on colo PostgreSQL and on prod RDS. The two results must be equal. Write both in the cutover note.

```sql
SELECT string_agg(
  format(
    'SELECT %L AS table_name, count(*)::bigint AS rows FROM %I.%I',
    c.relname, n.nspname, c.relname
  ),
  E'\nUNION ALL\n' ORDER BY c.relname
) AS row_check
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r';
```

Set sequences on prod RDS from the colo values. Run this on the colo and copy the printed statements onto prod RDS. Skip a sequence that has never been called. Do not run `setval` on the colo.

```sql
SELECT format(
  'SELECT setval(%L::regclass, %s);',
  format('%I.%I', schemaname, sequencename),
  last_value
)
FROM pg_sequences
WHERE schemaname = 'public' AND last_value IS NOT NULL;
```

Sync prod. This is the first time those pods exist.

```bash
argocd app sync storefront-prod
```

The Ingress on that sync adds the host rule to the existing load balancer. Then `GET /health` on those pods, the same port-forward check as step 7, in namespace `storefront-prod`. Write the go line only after that 200, and point public DNS at the load balancer.

On a no-go after the sync, scale prod to 0 and stop DMS before leaving the window:

```bash
argocd app set storefront-prod --source-position 1 --helm-set replicaCount=0
argocd app sync storefront-prod
aws dms stop-replication-task --replication-task-arn "$TASK_ARN"
```

## 10. Rollback of a go

Same tools, in this order. Times start when the decision is made.

`archiv`, 30 minutes: point private DNS back at the colo machine, stop the cutover instance, keep the snapshot.

`storefront`, 15 minutes:

```bash
argocd app set storefront-prod --source-position 1 --helm-set replicaCount=0
argocd app sync storefront-prod
aws dms stop-replication-task --replication-task-arn "$TASK_ARN"
```

Then point public DNS back at the colo virtual machine and revert the Git digest pin. Do not sync prod again in that window. Rows written to RDS after the go line are not copied back.

## 11. Seven days, then wave 3

Leave the colo machines, colo PostgreSQL, and the VPN up for seven days. RDS is the writer for `storefront` if that go line was written. If the prod secret version changes, roll the deployment after External Secrets has updated `storefront-db-prod`.

After those seven days with no open rollback, delete the site-to-site VPN and power off the colo machines. This repository has no code for that deletion.

The two archive users then reach the private instance with the Session Manager plugin:

```bash
aws ssm start-session \
  --target "$INSTANCE_ID" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["8443"],"localPortNumber":["8443"]}'
```

They use `https://127.0.0.1:8443` on their own machine. The instance still has no public address.
