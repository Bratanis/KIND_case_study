# main.tf
# Step 1: Tell Terraform what providers (plugins) we need
terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"
    }
    # For nginx
    # helm = {
    #   source  = "hashicorp/helm"
    #   version = "~> 3.0.0"
    # }
  }
}


# Step 2: Configure the KIND provider (no config needed!)
provider "kind" {}

# Step 3: Create a simple KIND cluster
resource "kind_cluster" "default" {
  name = "demo-clicker-cluster"
  node_image      = "kindest/node:latest"
     kubeconfig_path = pathexpand("/tmp/config")
     wait_for_ready  = true

     kind_config {
       kind        = "Cluster"
       api_version = "kind.x-k8s.io/v1alpha4"

       node {
           role = "control-plane"
           extra_port_mappings {
               container_port = 80
               host_port      = 80
           }
       }

       node {
           role = "worker"
       }
   }
}

# Step 4: Configure Kubernetes provider to talk to our new cluster
provider "kubernetes" {
  # These values come from the cluster we just created above
  host = kind_cluster.my_cluster.endpoint
  
  client_certificate     = kind_cluster.my_cluster.client_certificate
  client_key            = kind_cluster.my_cluster.client_key
  cluster_ca_certificate = kind_cluster.my_cluster.cluster_ca_certificate
}

# Step 5: Create our three namespaces (dev, test, prod)
resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
  }
  
  # Make sure the cluster exists first
  depends_on = [kind_cluster.my_cluster]
}

resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
  }
  
  depends_on = [kind_cluster.my_cluster]
}

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
  }
  
  depends_on = [kind_cluster.my_cluster]
}

# Step 6: Create a simple deployment in the dev namespace
resource "kubernetes_deployment" "demo_app_dev" {
  metadata {
    name      = "demo-clicker"
    namespace = "dev"
  }
  
  spec {
    replicas = 1  # Just one copy of our app
    
    selector {
      match_labels = {
        app = "demo-clicker"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "demo-clicker"
        }
      }
      
      spec {
        container {
          name  = "demo-clicker"
          image = "demo-clicker:v1"
          
          port {
            container_port = 8080
          }
        }
      }
    }
  }
  
  depends_on = [kubernetes_namespace.dev]
}

# Step 7: Create a service to access our app
resource "kubernetes_service" "demo_app_dev" {
  metadata {
    name      = "demo-clicker-service"
    namespace = "dev"
  }
  
  spec {
    selector = {
      app = "demo-clicker"
    }
    
    port {
      port        = 80
      target_port = 8080
    }
    
    # This makes it accessible from outside the cluster
    type = "NodePort"
  }
  
  depends_on = [kubernetes_deployment.demo_app_dev]
}

# Step 8: Show useful information after deployment
output "cluster_name" {
  value = "my-simple-cluster"
}

output "kubectl_command" {
  value = "kubectl cluster-info --context kind-my-simple-cluster"
}

output "see_namespaces" {
  value = "kubectl get namespaces"
}

output "see_pods" {
  value = "kubectl get pods -n dev"
}
