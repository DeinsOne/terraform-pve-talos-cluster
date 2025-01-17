output "subnet" {
  description = "a subnet cluster nodes are to belong to, should be /24 network covering ips of vms, is required to correctly select node ip to apply machine configs"
  value       = var.subnet
}


output "pool" {
  description = "pve pool id instances are added to"
  value       = var.pool
}


output "cluster-name" {
  description = "name of talos k8s cluster"
  value       = var.cluster-name
}


output "image" {
  description = "default talos os image"
  value       = var.image
}


output "version-talos" {
  description = "version of talos installer image to use"
  value       = var.version-talos
}


output "version-k8s" {
  description = "default version of k8s components images used"
  value       = var.version-k8s
}


output "talosconfig_raw" {
  description = "raw talosconfig file of a provisioned cluster"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}


output "kubeconfig" {
  description = "kubeconfig collection as returned by talos kubeconfig provider of a provisioned cluster"
  value       = talos_cluster_kubeconfig.this
  sensitive   = true
}


output "control-plane-types" {
  description = "types of control planes"
  value       = var.control-plane-types
}


output "vms" {
  description = "provisioned proxmox vms of talos nodes"
  value       = proxmox_virtual_environment_vm.instances
}


output "template-args" {
  description = "default template arguments passed to machine config patches"
  value       = var.template-args
  sensitive   = true
}


output "instances" {
  description = "snapshot of desired vms configurations, including overrides merged, includes sensitive template args"
  value       = local.instances
  sensitive   = true
}
