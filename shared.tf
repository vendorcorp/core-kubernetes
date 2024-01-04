################################################################################
# Load Vendor Corp Shared Infra
################################################################################
module "shared" {
  source                   = "git::ssh://git@github.com/vendorcorp/terraform-shared-infrastructure.git?ref=v0.6.1"
  environment              = var.environment
  default_eks_cluster_name = var.default_eks_cluster_name
}

################################################################################
# Load Vendor Corp Private Shared Infra
################################################################################
module "shared_private" {
  source                   = "git::ssh://git@github.com/vendorcorp/terraform-shared-private-infrastructure.git?ref=v0.1.0"
  environment              = var.environment
}

data "aws_eks_cluster" "vendorcorp_eks_cluster" {
  name = var.default_eks_cluster_name
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = data.aws_eks_cluster.vendorcorp_eks_cluster.arn
}
