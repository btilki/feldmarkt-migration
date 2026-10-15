variable "aws_region" {
  type        = string
  description = "Region of the existing landing zone."
  default     = "eu-central-1"
}

variable "name" {
  type        = string
  description = "Name prefix. Lowercase, used in RDS and DMS identifiers."
  default     = "feldmarkt-storefront"
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC. This stack does not create one."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "At least two existing private subnets in different availability zones."

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "RDS needs two private subnets."
  }
}

variable "nonprod_client_security_group_id" {
  type        = string
  description = "Security group attached only to dev and stage storefront pods. Not the shared EKS node group."
}

variable "prod_client_security_group_id" {
  type        = string
  description = "Security group attached only to prod storefront pods. Not the shared EKS node group, and not the nonprod client group."
}

variable "colo_cidr" {
  type        = string
  description = "Frankfurt colo CIDR. DMS reaches colo PostgreSQL over the VPN."

  validation {
    condition     = var.colo_cidr != "0.0.0.0/0"
    error_message = "The colo path must not be the open internet."
  }
}

variable "postgres_engine_version" {
  type        = string
  description = "RDS engine version. Must be the same major version as colo PostgreSQL (INV-3)."
}

variable "database_name" {
  type        = string
  description = "Database name. Same on the colo and on both RDS instances."
  default     = "storefront"
}

variable "schema_name" {
  type        = string
  description = "Schema DMS copies. Same schema on the target. No rewrite."
  default     = "public"
}

variable "colo_postgres_host" {
  type        = string
  description = "Private hostname of PostgreSQL on the storefront virtual machine."
}

variable "colo_postgres_secret_arn" {
  type        = string
  description = "Secrets Manager ARN with JSON keys username and password for the colo database. Not a password in Terraform."
}

variable "tags" {
  type        = map(string)
  description = "Extra tags."
  default     = {}
}
