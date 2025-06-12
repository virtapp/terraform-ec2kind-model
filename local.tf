###---<Terraform Providers>---###
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.65.0"
    }

    kind = {
      source  = "kyma-incubator/kind"
      version = "0.0.11"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.9.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.11.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.0.0"
    }

    external = {
      source = "hashicorp/external"
      version = "2.1.0"
   }
 }

  required_version = ">= 0.14.8"
}

###---<Local Environment Configuration>---###
provider "kind" {
}

provider "kubernetes" {
  config_path = pathexpand(var.kind_cluster_config_path)
}

resource "kind_cluster" "default" {
  name            = var.kind_cluster_name
  kubeconfig_path = pathexpand(var.kind_cluster_config_path)
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      image = "kindest/node:v1.23.4"

      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

  }
}
