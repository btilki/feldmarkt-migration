# Wave 1 landing shape for archiv.
# MGN launches the cutover instance. This stack does not create an EC2 instance
# and does not copy the disk. The snapshot before DNS is a line in docs/cutover.md.

locals {
  tags = merge(var.tags, {
    Project  = "feldmarkt-migration"
    Wave     = "1"
    Workload = "archiv"
  })
}

resource "aws_security_group" "cutover" {
  name        = "${var.name}-cutover"
  description = "archiv cutover. Port 8443 from archive clients. No SSH."
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name}-cutover" })
}

resource "aws_vpc_security_group_ingress_rule" "archive_clients" {
  security_group_id = aws_security_group.cutover.id
  description       = "Archive clients"
  cidr_ipv4         = var.archive_clients_cidr
  ip_protocol       = "tcp"
  from_port         = 8443
  to_port           = 8443
  tags              = local.tags
}

resource "aws_vpc_security_group_egress_rule" "cutover_ssm" {
  security_group_id = aws_security_group.cutover.id
  description       = "Systems Manager through endpoints already in the VPC"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  tags              = local.tags
}

resource "aws_security_group" "replication" {
  name        = "${var.name}-replication"
  description = "MGN replication servers. TCP 1500 from the colo only."
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name}-replication" })
}

resource "aws_vpc_security_group_ingress_rule" "replication_from_colo" {
  security_group_id = aws_security_group.replication.id
  description       = "MGN data plane from the colo over the VPN"
  cidr_ipv4         = var.colo_cidr
  ip_protocol       = "tcp"
  from_port         = 1500
  to_port           = 1500
  tags              = local.tags
}

resource "aws_vpc_security_group_egress_rule" "replication_api" {
  security_group_id = aws_security_group.replication.id
  description       = "MGN control plane on 443 through the existing private path"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  tags              = local.tags
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cutover" {
  name               = "${var.name}-ssm"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.cutover.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cutover" {
  name = "${var.name}-ssm"
  role = aws_iam_role.cutover.name
  tags = local.tags
}

resource "aws_launch_template" "cutover" {
  name                   = "${var.name}-cutover"
  description            = "Launch shape for the MGN cutover instance. No AMI. MGN supplies the replicated machine."
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.cutover.name
  }

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = var.private_subnet_id
    security_groups             = [aws_security_group.cutover.id]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${var.name}-cutover" })
  }

  tags = local.tags
}
