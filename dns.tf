resource "aws_route53_zone" "vendorcorp_internal" {
  name    = "vendorcorp.internal"
  comment = "Vendor Corp internal DNS Zone"
  tags    = var.default_resource_tags

  vpc {
    vpc_id = module.shared.vpc_id
  }
}
