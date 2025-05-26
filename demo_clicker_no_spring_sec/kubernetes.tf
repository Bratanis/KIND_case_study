# kubernetes.tf

resource "null_resource" "load_docker_image" {
  triggers = {
    cluster_id = kind_cluster.default.id
    image_tag  = var.image_tag
  }

  provisioner "local-exec" {
    command = "kind load docker-image demo-clicker:${var.image_tag} --name ${var.kind_cluster_name}-${var.environment}"
  }

  depends_on = [kind_cluster.default]
}

# Create namespace
resource "kubernetes_namespace" "app" {
  # depends_on = [kind_cluster.default]
  depends_on = [null_resource.wait_for_ingress_nginx, kind_cluster.default, null_resource.load_docker_image]
  metadata {
    name = "demo-clicker-${var.environment}"
  }
}

# Deployment
resource "kubernetes_deployment" "app" {
  depends_on = [kubernetes_namespace.app]
  
  metadata {
    name      = "demo-clicker-deployment-${var.environment}"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  spec {
    replicas = var.replica_count
    
    selector {
      match_labels = {
        app = "demo-clicker-${var.environment}"
      }
    }
    
    template {
      metadata {
        labels = {
          app         = "demo-clicker-${var.environment}"
          environment = var.environment
        }
      }
      
      spec {
        container {
          name  = "demo-clicker"
          image = "demo-clicker:${var.image_tag}"
          
          port {
            container_port = 8080
            name          = "http"
          }
          
          port {
            container_port = 8081
            name          = "management"
          }
          
          resources {
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
          }
          
          security_context {
            allow_privilege_escalation = false
            run_as_non_root           = true
          }
          
          env {
            name  = "MANAGEMENT_SERVER_PORT"
            value = "8081"
          }
          
          env {
            name  = "MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE"
            value = "health"
          }
          
          env {
            name  = "MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS"
            value = "never"
          }
          
          liveness_probe {
            http_get {
              path = "/actuator/health"
              port = 8081
            }
            initial_delay_seconds = 30
            period_seconds       = 30
          }
          
          readiness_probe {
            http_get {
              path = "/actuator/health"
              port = 8081
            }
            initial_delay_seconds = 5
            period_seconds       = 10
          }
        }
      }
    }
  }
}

# Main application service
resource "kubernetes_service" "app" {
  depends_on = [kubernetes_namespace.app]
  
  metadata {
    name      = "demo-clicker-${var.environment}"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  spec {
    selector = {
      app = "demo-clicker-${var.environment}"
    }
    
    port {
      port        = 80
      target_port = 8080
      name        = "http"
    }
    
    type = "ClusterIP"
  }
}

# Management service (cluster-internal only)
resource "kubernetes_service" "management" {
  depends_on = [kubernetes_namespace.app]
  
  metadata {
    name      = "demo-clicker-management-${var.environment}"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  spec {
    selector = {
      app = "demo-clicker-${var.environment}"
    }
    
    port {
      port        = 8081
      target_port = 8081
      name        = "management"
    }
    
    type = "ClusterIP"
  }
}

# Ingress
resource "kubernetes_ingress_v1" "app" {
  depends_on = [kubernetes_namespace.app]
  
  metadata {
    name      = "demo-clicker-ingress-${var.environment}"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  spec {
    ingress_class_name = "nginx"
    
    rule {
      host = var.ingress_host
      
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          
          backend {
            service {
              name = "demo-clicker-${var.environment}"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
