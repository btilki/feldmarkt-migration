variable "aws_region" {
  type        = string
  description = "Region of the existing landing zone."
  default     = "eu-central-1"
}

variable "name" {
  type        = string
  description = "Name prefix for the archiv landing resources."
  default     = "feldmarkt-archiv"
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC. This stack does not create one."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR of the existing VPC. Cutover egress for Systems Manager stays inside it."
}

variable "private_subnet_id" {
  type        = string
  description = "Existing private subnet. MGN stages and launches archiv here. No public address."
}

variable "archive_clients_cidr" {
  type        = string
  description = "Private CIDR allowed to call archiv on port 8443."

  validation {
    condition     = var.archive_clients_cidr != "0.0.0.0/0"
    error_message = "archiv must not be published to the internet."
  }
}

variable "colo_cidr" {
  type        = string
  description = "Frankfurt colo CIDR. MGN replication servers accept TCP 1500 only from here, over the VPN."

  validation {
    condition     = var.colo_cidr != "0.0.0.0/0"
    error_message = "Replication must not be open to the internet."
  }
}

variable "tags" {
  type        = map(string)
  description = "Extra tags."
  default     = {}
}
