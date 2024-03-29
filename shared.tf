################################################################################
# Load Vendor Corp Private Shared Infra
################################################################################
module "shared" {
  source                   = "git::ssh://git@github.com/vendorcorp/terraform-shared-infrastructure.git?ref=v1.2.0"
}

module "shared_private" {
  source                   = "git::ssh://git@github.com/vendorcorp/terraform-shared-private-infrastructure.git?ref=v1.5.0"
  environment              = var.environment
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = module.shared.eks_cluster_arn
}
