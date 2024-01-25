# See https://github.com/TwiN/gatus

terraform {
  required_version = ">= 1.4.5"
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.15.0"
    }
  }
}

################################################################################
# PostgreSQL Provider
################################################################################
provider "postgresql" {
  scheme          = "awspostgres"
  host            = module.shared.pgsql_cluster_endpoint_write
  port            = module.shared.pgsql_cluster_port
  database        = "postgres"
  username        = var.pg_admin_username
  password        = var.pg_admin_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}

################################################################################
# Create a Database for Gatus
################################################################################
resource "postgresql_role" "gatus" {
  name     = "gatus"
  login    = true
  password = "gatus"
}

resource "postgresql_database" "gatus" {
  name              = "gatus"
  owner             = "gatus"
  template          = "template0"
  lc_collate        = "C"
  connection_limit  = -1
  allow_connections = true
}

################################################################################
# Create Namespace
################################################################################
resource "kubernetes_namespace" "gatus" {
  metadata {
    name = "gatus"
  }
}

################################################################################
# Create ClusterRole & ClusterRoleBinding
#
# Required for the sidecar to be able to list ConfigMaps from all Namespaces
################################################################################
resource "kubernetes_cluster_role" "gatus" {
  metadata {
    name = "gatus"
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "gatus" {
  metadata {
    name = "gatus"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "gatus"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "gatus"
    namespace = kubernetes_namespace.gatus.metadata[0].name
  }
}

################################################################################
# Deploy gatus
#
# Seehttps://github.com/minicloudlabs/helm-charts/tree/main/charts/gatus#configuration
################################################################################
resource "helm_release" "gatus" {
  name       = "gatus"
  repository = "https://minicloudlabs.github.io/helm-charts"
  chart      = "gatus"
  version    = "3.4.1"
  namespace  = "gatus"

  values = [
    "${file("values/gatus.yaml")}"
  ]

  set {
    name = "env.GATUS_CONFIG_PATH"
    value = "/shared-config/"
  }

  set {
    name = "env.PGSQL_HOST"
    value = module.shared.pgsql_cluster_endpoint_write
  }

  set {
    name = "config.storage.path"
    value = "postgres://gatus:gatus@$${PGSQL_HOST}/gatus"
  }

  set {
    name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = module.shared_private.vendorcorp_cert_arn
  }

  set {
    name = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = "status.${module.shared_private.dns_zone_vendorcorp_name}"
  }

  set_list {
    name = "ingress.hosts"
    value = ["status.${module.shared_private.dns_zone_vendorcorp_name}"]
  }

  set {
    name = "nodeSelector.instancegroup"
    value = "vendorcorp-core"
  }

  set {
    name = "tolerations[0].key"
    value = "dedicated"
  }

  set {
    name = "tolerations[0].value"
    value = "vendorcorp-core"
  }

  set {
    name = "tolerations[0].operator"
    value = "Equal"
  }

  set {
    name = "tolerations[0].effect"
    value = "NoSchedule"
  }
}