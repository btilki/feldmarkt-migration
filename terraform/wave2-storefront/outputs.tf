output "nonprod_endpoint" {
  description = "Dev and stage only. Not the DMS target."
  value       = aws_db_instance.nonprod.address
}

output "nonprod_secret_arn" {
  description = "Secret for the nonprod master user. Keys username and password."
  value       = aws_db_instance.nonprod.master_user_secret[0].secret_arn
}

output "prod_endpoint" {
  description = "DMS target. Production storefront uses this only after the Sunday row check."
  value       = aws_db_instance.prod.address
}

output "prod_secret_arn" {
  description = "Secret for the prod master user. Not committed to Git."
  value       = aws_db_instance.prod.master_user_secret[0].secret_arn
}

output "dms_task_arn" {
  description = "Full-load and CDC task. Created stopped."
  value       = aws_dms_replication_task.storefront.replication_task_arn
}

output "ecr_repository_url" {
  description = "Immutable repository CI pushes to."
  value       = aws_ecr_repository.storefront.repository_url
}
