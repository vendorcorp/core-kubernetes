# See https://prometheus.io/docs/prometheus/latest/installation/

################################################################################
# Create Namespace
################################################################################
resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

################################################################################
# Deploy metrics-server
#
# See https://artifacthub.io/packages/helm/metrics-server/metrics-server
################################################################################
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "25.8.2"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name

  values = [
    "${file("values/prometheus.yaml")}"
  ]

  set {
    name = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = module.shared_private.vendorcorp_cert_arn
  }

  set {
    name = "server.ingress.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = "monitoring.${module.shared_private.dns_zone_vendorcorp_name}"
  }

  set_list {
    name = "server.ingress.hosts"
    value = ["monitoring.${module.shared_private.dns_zone_vendorcorp_name}"]
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