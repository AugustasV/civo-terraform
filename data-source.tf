data "civo_instances_size" "medium" {
    filter {
        key = "name"
        values = ["g2.medium"]
    }
}
data "civo_kubernetes_version" "stable" {
    filter {
        key = "type"
        values = ["stable"]
    }
}