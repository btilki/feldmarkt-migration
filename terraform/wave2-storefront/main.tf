# Wave 2 data path for storefront.
# Two private RDS instances. DMS replicates the colo database into prod only.
# Dev and stage must not use the prod instance. This stack does not start the DMS task.

locals {
  tags = merge(var.tags, {
    Project  = "feldmarkt-migration"
    Wave     = "2"
    Workload = "storefront"
  })
}

resource "aws_security_group" "rds_nonprod" {
  name        = "${var.name}-rds-nonprod"
  description = "Nonprod PostgreSQL from dev and stage pods only."
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name}-rds-nonprod" })
}

resource "aws_security_group" "rds_prod" {
  name        = "${var.name}-rds-prod"
  description = "Prod PostgreSQL from prod pods and DMS only."
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name}-rds-prod" })

  lifecycle {
    precondition {
      condition     = var.prod_client_security_group_id != var.nonprod_client_security_group_id
      error_message = "Prod and nonprod clients must use different security groups."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "nonprod_from_clients" {
  security_group_id            = aws_security_group.rds_nonprod.id
  description                  = "Dev and stage storefront pods"
  referenced_security_group_id = var.nonprod_client_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  tags                         = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "prod_from_clients" {
  security_group_id            = aws_security_group.rds_prod.id
  description                  = "Prod storefront pods"
  referenced_security_group_id = var.prod_client_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  tags                         = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "prod_from_dms" {
  security_group_id            = aws_security_group.rds_prod.id
  description                  = "DMS replication instance"
  referenced_security_group_id = aws_security_group.dms.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  tags                         = local.tags
}

resource "aws_security_group" "dms" {
  name        = "${var.name}-dms"
  description = "DMS. No inbound from the internet. Egress to colo PostgreSQL and RDS."
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name}-dms" })
}

resource "aws_vpc_security_group_egress_rule" "dms_to_colo" {
  security_group_id = aws_security_group.dms.id
  description       = "Colo PostgreSQL over the VPN"
  cidr_ipv4         = var.colo_cidr
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  tags              = local.tags
}

resource "aws_vpc_security_group_egress_rule" "dms_to_rds" {
  security_group_id            = aws_security_group.dms.id
  description                  = "Prod RDS"
  referenced_security_group_id = aws_security_group.rds_prod.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  tags                         = local.tags
}

resource "aws_vpc_security_group_egress_rule" "dms_api" {
  security_group_id = aws_security_group.dms.id
  description       = "DMS control plane through the existing private path"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  tags              = local.tags
}

resource "aws_db_subnet_group" "storefront" {
  name       = var.name
  subnet_ids = var.private_subnet_ids
  tags       = local.tags
}

resource "aws_db_instance" "nonprod" {
  identifier                   = "${var.name}-nonprod"
  engine                       = "postgres"
  engine_version               = var.postgres_engine_version
  instance_class               = "db.t4g.micro"
  allocated_storage            = 20
  db_name                      = var.database_name
  username                     = var.database_name
  manage_master_user_password  = true
  db_subnet_group_name         = aws_db_subnet_group.storefront.name
  vpc_security_group_ids       = [aws_security_group.rds_nonprod.id]
  publicly_accessible          = false
  storage_encrypted            = true
  auto_minor_version_upgrade   = false
  backup_retention_period      = 1
  skip_final_snapshot          = true
  deletion_protection          = false
  performance_insights_enabled = false
  tags                         = merge(local.tags, { Data = "nonprod" })
}

resource "aws_db_instance" "prod" {
  identifier                   = "${var.name}-prod"
  engine                       = "postgres"
  engine_version               = var.postgres_engine_version
  instance_class               = "db.t4g.small"
  allocated_storage            = 20
  db_name                      = var.database_name
  username                     = var.database_name
  manage_master_user_password  = true
  db_subnet_group_name         = aws_db_subnet_group.storefront.name
  vpc_security_group_ids       = [aws_security_group.rds_prod.id]
  publicly_accessible          = false
  storage_encrypted            = true
  auto_minor_version_upgrade   = false
  backup_retention_period      = 7
  skip_final_snapshot          = false
  final_snapshot_identifier    = "${var.name}-prod-final"
  deletion_protection          = true
  performance_insights_enabled = false
  tags                         = merge(local.tags, { Data = "prod" })
}

data "aws_iam_policy_document" "dms_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "dms.amazonaws.com",
        "dms.${var.aws_region}.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "dms_vpc" {
  name               = "dms-vpc-role"
  assume_role_policy = data.aws_iam_policy_document.dms_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "dms_vpc" {
  role       = aws_iam_role.dms_vpc.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

resource "aws_iam_role" "dms_secrets" {
  name               = "${var.name}-dms-secrets"
  assume_role_policy = data.aws_iam_policy_document.dms_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "dms_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.colo_postgres_secret_arn, aws_db_instance.prod.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_role_policy" "dms_secrets" {
  name   = "${var.name}-dms-secrets"
  role   = aws_iam_role.dms_secrets.id
  policy = data.aws_iam_policy_document.dms_secrets.json
}

resource "aws_dms_replication_subnet_group" "storefront" {
  replication_subnet_group_id          = var.name
  replication_subnet_group_description = "Private subnets for storefront DMS"
  subnet_ids                           = var.private_subnet_ids
  tags                                 = local.tags

  depends_on = [aws_iam_role_policy_attachment.dms_vpc]
}

resource "aws_dms_replication_instance" "storefront" {
  replication_instance_id     = var.name
  replication_instance_class  = "dms.t3.small"
  allocated_storage           = 50
  replication_subnet_group_id = aws_dms_replication_subnet_group.storefront.replication_subnet_group_id
  vpc_security_group_ids      = [aws_security_group.dms.id]
  publicly_accessible         = false
  tags                        = local.tags
}

resource "aws_dms_endpoint" "colo" {
  endpoint_id                     = "${var.name}-colo"
  endpoint_type                   = "source"
  engine_name                     = "postgres"
  ssl_mode                        = "require"
  server_name                     = var.colo_postgres_host
  port                            = 5432
  database_name                   = var.database_name
  secrets_manager_arn             = var.colo_postgres_secret_arn
  secrets_manager_access_role_arn = aws_iam_role.dms_secrets.arn
  tags                            = local.tags
}

resource "aws_dms_endpoint" "prod" {
  endpoint_id                     = "${var.name}-prod"
  endpoint_type                   = "target"
  engine_name                     = "postgres"
  ssl_mode                        = "require"
  server_name                     = aws_db_instance.prod.address
  port                            = aws_db_instance.prod.port
  database_name                   = var.database_name
  secrets_manager_arn             = aws_db_instance.prod.master_user_secret[0].secret_arn
  secrets_manager_access_role_arn = aws_iam_role.dms_secrets.arn
  tags                            = local.tags
}

resource "aws_dms_replication_task" "storefront" {
  replication_task_id      = var.name
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.storefront.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.colo.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.prod.endpoint_arn
  start_replication_task   = false

  table_mappings = jsonencode({
    rules = [{
      "rule-type" = "selection"
      "rule-id"   = "1"
      "rule-name" = "storefront-schema"
      "object-locator" = {
        "schema-name" = var.schema_name
        "table-name"  = "%"
      }
      "rule-action" = "include"
    }]
  })

  replication_task_settings = jsonencode({
    TargetMetadata = {
      TargetSchema       = ""
      SupportLobs        = true
      FullLobMode        = true
      LobChunkSize       = 64
      LimitedSizeLobMode = false
      LobMaxSize         = 0
    }
    FullLoadSettings = {
      TargetTablePrepMode = "DO_NOTHING"
    }
    ValidationSettings = {
      EnableValidation = true
      ValidationMode   = "ROW_LEVEL"
    }
    Logging = {
      EnableLogging = true
    }
  })

  tags = local.tags
}

resource "aws_ecr_repository" "storefront" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.tags
}
