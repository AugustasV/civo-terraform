provider "kubernetes" {
  load_config_file = false
  host  = civo_kubernetes_cluster.my-cluster.api_endpoint
  username = yamldecode(civo_kubernetes_cluster.my-cluster.kubeconfig).users[0].user.username
  password = yamldecode(civo_kubernetes_cluster.my-cluster.kubeconfig).users[0].user.password
  cluster_ca_certificate = base64decode(
    yamldecode(civo_kubernetes_cluster.my-cluster.kubeconfig).clusters[0].cluster.certificate-authority-data
  )
}

resource "civo_firewall" "my-firewall" {
    name = "my-firewall"
}

# Create a firewall rule
resource "civo_firewall_rule" "kubernetes" {
    firewall_id = civo_firewall.my-firewall.id
    protocol = "tcp"
    start_port = "6443"
    end_port = "6443"
    cidr = ["0.0.0.0/0"]
    direction = "ingress"
    label = "kubernetes-api-server"
}

resource "civo_kubernetes_cluster" "tf-cluster" {
    name = "my-cluster"
    applications = "-Traefik"
    num_target_nodes = 2
    firewall_id = civo_firewall.my-firewall.id
    pools {
        size = element(data.civo_instances_size.xsmall.sizes, 0).name
        node_count = 1
    }
    kubernetes_version = element(data.civo_kubernetes_version.stable.versions, 0).version
    target_nodes_size = element(data.civo_instances_size.medium.sizes, 0).name
}

# provider "helm" {
#   kubernetes {
#     load_config_file       = false
#     host                   = civo_kubernetes_cluster.my-cluster.api_endpoint
#     cluster_ca_certificate = base64decode(yamldecode(civo_kubernetes_cluster.my-cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
#     token                  = "pryKTQqsNntXxfVEOB3djMPRY1uCL0Dbc7Z05oA8S4vhl6WgGk"
#   }
# }
resource "local_file" "kubeconfig" {
    content  = civo_kubernetes_cluster.tf-cluster.kubeconfig
    filename = "config/config.yml"
}

provider "helm" {
  kubernetes {
    config_path = "config/config.yml"
  }
}

resource "helm_release" "nginx" {
  name  = "nginx"
  chart = "stable/nginx-ingress"
  depends_on = [
    civo_kubernetes_cluster.tf-cluster
  ]
  set {
    name  = "rbac.create"
    value = "true"
  }
}

resource "helm_release" "prometheus" {
  name  = "prometheus"
  chart = "stable/prometheus"
  depends_on = [
    civo_kubernetes_cluster.tf-cluster
  ]
  set {
    name  = "rbac.create"
    value = "true"
  }
}
resource "civo_dns_domain_name" "main" {
    name = "thisnode.tk"
}
resource "civo_dns_domain_record" "k8s" {
    domain_id = civo_dns_domain_name.main.id
    type = "CNAME"
    name = "@"
    value = civo_kubernetes_cluster.tf-cluster.dns_entry
    ttl = 600
    depends_on = [civo_dns_domain_name.main, civo_kubernetes_cluster.tf-cluster]    
}
resource "helm_release" "grafana" {
  name  = "grafana"
  chart = "stable/grafana"
  values = [file("config/grafana.yaml")]
  depends_on = [
    civo_kubernetes_cluster.tf-cluster
  ]
  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.hosts"
    value = "{thisnode.tk}"
  }
  set {
    name  = "rbac.create"
    value = "true"
  }
  //try to get prometheus
  set {
    name = "sidecar.datasources.enabled"
    value = "true"
  }
  set {
    name = "sidecar.datasources.label"
    value = "grafana-datasource"
  }
  // try to find dashboards
  set {
    name = "sidecar.dashboards.enabled"
    value = "true"
  }
  set {
    name = "sidecar.dashboards.label"
    value = "grafana-datasource"
  }
  
}

provider "grafana" {
  url  = "http://thisnode.tk"
  auth = "admin/CXmnWaSIoazDxpSWR0CrVnDiCIdkybcJKD0Wp3Oh"
}

# resource "grafana_dashboard" "metrics" {
#   config_json = "${file("grafana-dashboard.json")}"
# }

resource "grafana_data_source" "prometheus" {
  type          = "proxy"
  name          = "prometheus"
  url           = "http://prometheus-server"
}
