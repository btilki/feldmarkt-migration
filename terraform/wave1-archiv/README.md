# Wave 1 — `archiv` landing shape

Blueprint only. Do not apply this stack as part of writing the repository. It has not been applied to a cloud account.

MGN launches the cutover instance after the agent on the Frankfurt virtual machine has replicated it. This stack is the network and access that instance lands in.

| Resource | Job |
|----------|-----|
| Security group `cutover` | TCP 8443 from the archive clients only. No port 22. Egress 443 stays inside the VPC CIDR range for Systems Manager. |
| IAM instance profile | `AmazonSSMManagedInstanceCore`. Operators use Systems Manager. |
| Launch template | Private subnet, no public IP address, the cutover security group, IMDSv2. No AMI. MGN supplies the replicated machine. There is no `aws_instance`. |
| Replication security group | TCP 1500 from the colo CIDR only. Egress 443 is the MGN control plane. |

The MGN replication template is not a Terraform resource in the AWS provider. The output `mgn_replication_settings` is the template MGN must use: the existing private subnet, the replication security group, no public IP, and `PRIVATE_IP` data plane routing.

The VPC, the private subnet, the site-to-site VPN, and a private path for TCP 443 from that subnet to the MGN service already belong to the landing zone. This stack does not create a VPC, a NAT gateway, or a public address.

The snapshot of the data volume is taken before DNS changes. That is a line in [`docs/cutover.md`](../../docs/cutover.md), because the volume does not exist until MGN cutover.

Copy `terraform.tfvars.example` when you are ready to plan. `archive_clients_cidr` and `colo_cidr` cannot be `0.0.0.0/0`.
