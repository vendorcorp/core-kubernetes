# See https://prometheus.io/docs/prometheus/latest/installation/

################################################################################
# Create Namespace
################################################################################
resource "kubernetes_namespace" "keycprometheusloak" {
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
  namespace  = "prometheus"

  values = [
    "${file("values/prometheus.yaml")}"
  ]

  set {
    name = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = module.shared_private.vendorcorp_cert_arn
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