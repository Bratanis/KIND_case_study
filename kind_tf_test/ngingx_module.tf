# # nginx_ingress.tf
#
# provider "helm" {
#   kubernetes {
#     config_path = pathexpand(var.kind_cluster_config_path)
#   }
# }
#
# module "nginx-controller" {
#   source  = "terraform-iaac/nginx-controller/helm"
#   version = "2.3.0"
#
#   # Configure the module to work with Kind
#   namespace        = var.ingress_nginx_namespace
#   create_namespace = true # create if it doesnt exist
#
#   # Override values to match your Kind setup
#   additional_set = [
#     # allows the NGINX controller pods to bind directly to the host's network ports (80/443)
#     {
#       name  = "controller.hostPort.enabled"
#       value = "true"
#     },
#     {
#       name  = "controller.service.type"
#       value = "NodePort"
#     },
#     # {
#     #   name  = "controller.watchIngressWithoutClass"
#     #   value = "true"
#     # },
#     {
#       name  = "controller.nodeSelector.ingress-ready"
#       value = "true"
#     },
#     # {
#     #   name  = "controller.tolerations[0].effect"
#     #   value = "NoSchedule"
#     # },
#     # {
#     #   name  = "controller.tolerations[0].key"
#     #   value = "node-role.kubernetes.io/master"
#     # },
#     # {
#     #   name  = "controller.tolerations[0].operator"
#     #   value = "Equal"
#     # },
#     {
#       name  = "controller.tolerations[1].effect"
#       value = "NoSchedule"
#     },
#     {
#       name  = "controller.tolerations[1].key"
#       value = "node-role.kubernetes.io/control-plane"
#     },
#     {
#       name  = "controller.tolerations[1].operator"
#       value = "Equal"
#     },
#     {
#       name  = "controller.publishService.enabled"
#       value = "false"
#     },
#     {
#       name  = "controller.extraArgs.publish-status-address"
#       value = "localhost"
#     }
#   ]
#
#   depends_on = [kind_cluster.default]
# }
#
# resource "null_resource" "wait_for_ingress_nginx" {
#   triggers = {
#     key = uuid()
#   }
#
#   provisioner "local-exec" {
#     command = <<EOF
#       printf "\nWaiting for the nginx ingress controller...\n"
#       kubectl wait --namespace ${module.nginx-controller.namespace} \
#         --for=condition=ready pod \
#         --selector=app.kubernetes.io/component=controller \
#         --timeout=90s
#     EOF
#   }
#
#   depends_on = [module.nginx-controller]
# }
