# variables.tf

variable "kind_cluster_name" {
  type        = string
  description = "The name of the cluster."
  default     = "demo-clicker-cluster"
}

variable "kind_cluster_config_path" {
  type        = string
  description = "The location where this cluster's kubeconfig will be saved to."
  default     = "~/.kube/config"
}

variable "ingress_nginx_helm_version" {
  type        = string
  description = "The Helm version for the nginx ingress controller."
  default     = "4.12.2"
}

variable "ingress_nginx_namespace" {
  type        = string
  description = "The nginx ingress namespace (it will be created if needed)."
  default     = "ingress-nginx"
}


variable "environment" {
  type        = string
  description = "Environment name (dev/test/prod)"
}

variable "replica_count" {
  type        = number
  description = "Number of replicas"
  default     = 2
}

variable "image_tag" {
  type        = string
  description = "Docker image tag"
  default     = "v1"
}

variable "ingress_host" {
  type        = string
  description = "Ingress host"
  default     = "localhost"
}

variable "cpu_limit" {
  type        = string
  description = "CPU limit"
  default     = "0.5"
}

variable "memory_limit" {
  type        = string
  description = "Memory limit"
  default     = "1Gi"
}

variable "cpu_request" {
  type        = string
  description = "CPU request"
  default     = "0.1"
}

variable "memory_request" {
  type        = string
  description = "Memory request"
  default = "512Mi"
}

variable "host_http_port" {
  type        = number
  description = "Host port for HTTP traffic"
  default     = 80
}

variable "host_https_port" {
  type        = number
  description = "Host port for HTTPS traffic"
  default     = 443
}
