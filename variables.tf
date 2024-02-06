variable "default_resource_tags" {
  description = "List of tags to apply to all resources created in AWS"
  type        = map(string)
  default = {
    environment : "production"
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