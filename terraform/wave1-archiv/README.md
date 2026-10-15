# Wave 1 — `archiv` landing shape

Blueprint only. Do not apply this stack as part of writing the repository. It has not been applied to a cloud account.

**MGN** (**AWS Application Migration Service**) launches the cutover instance after the agent on the Frankfurt virtual machine has replicated it. This stack is the network and access that instance lands in.

| Resource | Job |
|----------|-----|
| Security group `cutover` | **TCP** (**Transmission Control Protocol**) 8443 from the archive clients only. No port 22. Egress 443 stays inside the **VPC** (**Virtual Private Cloud**) **CIDR** (**Classless Inter-Domain Routing**) range for Systems Manager. |
| **IAM** (**AWS Identity and Access Management**) instance profile | `AmazonSSMManagedInstanceCore`. Operators use Systems Manager. |
| Launch template | Private subnet, no public **IP** (**Internet Protocol**) address, the cutover security group, **IMDSv2** (**Instance Metadata Service version 2**). No **AMI** (**Amazon Machine Image**). MGN supplies the replicated machine. There is no `aws_instance`. |
| Replication security group | TCP 1500 from the colo CIDR only. Egress 443 is the MGN control plane. |

The MGN replication template is not a Terraform resource in the **AWS** (**Amazon Web Services**) provider. The output `mgn_replication_settings` is the template MGN must use: the existing private subnet, the replication security group, no public IP, and `PRIVATE_IP` data plane routing.

The VPC, the private subnet, the site-to-site **VPN** (**Virtual Private Network**), and a private path for TCP 443 from that subnet to the MGN service already belong to the landing zone. This stack does not create a VPC, a **NAT** (**Network Address Translation**) gateway, or a public address.

The snapshot of the data volume is taken before **DNS** (**Domain Name System**) changes. That is a line in [`docs/cutover.md`](../../docs/cutover.md), because the volume does not exist until MGN cutover.

Copy `terraform.tfvars.example` when you are ready to plan. `archive_clients_cidr` and `colo_cidr` cannot be `0.0.0.0/0`.
