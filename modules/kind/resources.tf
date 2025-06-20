
data "external" "subnet" {
  program = ["/bin/bash", "-c", "docker network inspect -f '{{json .IPAM.Config}}' kind | jq .[0]"]
  depends_on = [
    kind_cluster.default
  ]
}

provider "helm" {
  kubernetes {
    config_path = pathexpand(var.kind_cluster_config_path)
  }
}


resource "helm_release" "argocd" {
  name  = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "4.10.0"
  create_namespace = true
  timeout = 300

  values = [
    <<EOT
controller:
  enableStatefulSet: true

configs:
  secret:
    argocdServerAdminPassword: $2a$10$lgcvwdvggWeLl1AN14NWsePcWQczWHRQH2eiUNL9w/gN6NaelDl.G
   EOT
  ]
  depends_on = [kind_cluster.default]
}

resource "null_resource" "wait_for_argocd" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\nWaiting for the argocd controller will be installed...\n"
      kubectl wait --namespace ${helm_release.argocd.namespace} \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=server \
        --timeout=60s
    EOF
  }
  depends_on = [helm_release.argocd]
}

resource "helm_release" "metallb" {
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  namespace        = "metallb"
  version          = "0.10.3"
  create_namespace = true
  timeout = 300
  values = [
    <<-EOF
  configInline:
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.255.1-172.18.255.250
  EOF
  ]
  depends_on = [
    kind_cluster.default
  ]
}

resource "null_resource" "wait_for_metallb" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\nWaiting for the metallb controller...\n"
      kubectl wait --namespace ${helm_release.metallb.namespace} \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=speaker \
        --timeout=90s
    EOF
  }
  depends_on = [helm_release.metallb]
}


resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_helm_version

  namespace        = var.ingress_nginx_namespace
  create_namespace = true
  timeout = 300

  values = [
    <<EOT
controller:
  updateStrategy:
    type: "RollingUpdate"
    rollingUpdate:
      maxUnavailable: 1
  hostPort:
    enabled: true
  terminationGracePeriodSeconds: 0
  service:
    type: "LoadBalancer"
  watchIngressWithoutClass: true
  nodeSelector:
    ingress-ready: "true"
  tolerations:
    - key: "node-role.kubernetes.io/master"
      operator: "Equal"
      effect: "NoSchedule"
  publishService:
    enabled: true
EOT
  ]
  depends_on = [kind_cluster.default]
}

resource "null_resource" "wait_for_ingress_nginx" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\nWaiting for the nginx ingress controller...\n"
      kubectl wait --namespace ${helm_release.ingress_nginx.namespace} \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s
    EOF
  }

  depends_on = [helm_release.ingress_nginx]
}
