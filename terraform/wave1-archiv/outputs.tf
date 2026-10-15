output "cutover_security_group_id" {
  description = "Attach this to the MGN cutover instance."
  value       = aws_security_group.cutover.id
}

output "instance_profile_name" {
  description = "Systems Manager profile for the cutover instance."
  value       = aws_iam_instance_profile.cutover.name
}

output "launch_template_id" {
  description = "Values to copy into the launch template MGN creates. This stack does not start an instance."
  value       = aws_launch_template.cutover.id
}

output "mgn_replication_settings" {
  description = "Values the MGN replication template must use. The AWS provider has no resource for that template."
  value = {
    staging_area_subnet_id                  = var.private_subnet_id
    replication_servers_security_groups_ids = [aws_security_group.replication.id]
    associate_default_security_group        = false
    create_public_ip                        = false
    data_plane_routing                      = "PRIVATE_IP"
    default_large_staging_disk_type         = "GP3"
    ebs_encryption                          = "DEFAULT"
    replication_server_instance_type        = "t3.small"
    use_dedicated_replication_server        = false
  }
}
