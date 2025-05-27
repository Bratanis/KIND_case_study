# kind_cluster.tf

provider "kind" {
}

# provider "kubernetes" {
#   config_path    = pathexpand("~/.kube/config-${var.environment}")
#   config_context = "kind-${var.kind_cluster_name}-${var.environment}"
# }

# resource "kubernetes_manifest" "deployment" {
#   depends_on = [kind_cluster.default]
#   manifest = yamldecode(templatefile("deployment.yaml", {
#     environment    = var.environment
#     replica_count  = var.replica_count
#     image_tag      = var.image_tag
#     ingress_host   = var.ingress_host
#     cpu_limit      = var.cpu_limit
#     memory_limit   = var.memory_limit
#     cpu_request    = var.cpu_request
#     memory_request = var.memory_request
#   }))
# }

resource "kind_cluster" "default" {
  name            = "${var.kind_cluster_name}-${var.environment}"
  kubeconfig_path = pathexpand("~/.kube/config-${var.environment}")
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]

      extra_port_mappings {
        container_port = 80
        host_port = var.host_http_port
      }
      extra_port_mappings {
        container_port = 443
        host_port = var.host_https_port
      }

      # extra_port_mappings {
      #   container_port = 80
      #   host_port      = 80
      # }
      # extra_port_mappings {
      #   container_port = 443
      #   host_port      = 443
      # }
    }

    node {
      role = "worker"
    }
  }
}
