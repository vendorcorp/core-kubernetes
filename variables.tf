variable "aws_region" {
  description = "AWS Region that our deployment is targetting"
  type        = string
  default     = "us-east-2"
}

variable "default_resource_tags" {
  description = "List of tags to apply to all resources created in AWS"
  type        = map(string)
  default = {
    environment : "development"
    purpose : "vendorcorp"
    owner : "phorton@sonatype.com"
    sonatype-group : "se"
    vendorcorp-purpose : "core"
  }
}

# See https://docs.sonatype.com/display/OPS/Shared+Infrastructure+Initiative
variable "environment" {
  description = "Used as part of Sonatype's Shared AWS Infrastructure"
  type        = string
  default     = "production"
}

variable "default_eks_cluster_name" {
  description = "Name of the EKS Cluster for Vendor Corp"
  type        = string
  default     = "vendorcorp-oCBeuuDXqV"
}

variable "pg_admin_username" {
  description = "Administrator/Root user to access your PostgreSQL service."
  type        = string
  default     = "root"
}

variable "pg_admin_password" {
  description = "Administrator/Root password to access your PostgreSQL service."
  type        = string
  default     = null
  sensitive   = true
}

variable "ghrc_io_username" {
  description = "Username for ghrc.io OCI registry"
  type        = string
  default     = null
  sensitive   = true
}

variable "ghrc_io_password" {
  description = "Username for ghrc.io OCI registry"
  type        = string
  default     = null
  sensitive   = true
}