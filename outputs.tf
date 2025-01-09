output "region" {
  value = var.region
}


output "pool" {
  value = var.pool
}


output "cluster-name" {
  value = var.cluster-name
}


output "image" {
  value = var.image
}


output "version-talos" {
  value = var.version-talos
}


output "version-k8s" {
  value = var.version-k8s
}


output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}


output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}


output "instances" {
  value = local.instances
}
