data "civo_instances_size" "medium" {
    filter {
        key = "name"
        values = ["g2.medium"]
    }
}
data "civo_instances_size" "xsmall" {
    filter {
        key = "name"
        values = ["g3.xsmall"]
        match_by = "re"
    }

    filter {
        key = "type"
        values = ["instance"]
    }

}
data "civo_kubernetes_version" "stable" {
    filter {
        key = "type"
        values = ["stable"]
    }
}
