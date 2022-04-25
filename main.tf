terraform {
  required_providers {
    civo = {
      source = "civo/civo"
      version = "1.0.18"
    }
    grafana = {
      source = "grafana/grafana"
      version = "1.22.0"
    }
  }
}

provider "civo" {
  token = var.token
}
# provider "kubernetes" {
#   load_config_file = false
#   host  = civo_kubernetes_cluster.my-cluster.api_endpoint
#   username = yamldecode(civo_kubernetes_cluster.my-cluster.kubeconfig).users[0].user.username
#   password = yamldecode(civo_kubernetes_cluster.my-cluster.kubeconfig).users[0].user.password
#   cluster_ca_certificate = base64decode(
#     yamldecode(civo_kubernetes_cluster.my-cluster.kubeconfig).clusters[0].cluster.certificate-authority-data
#   )
# }

