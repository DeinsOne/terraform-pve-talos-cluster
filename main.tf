locals {
  machine-types = distinct(concat(
    [for key, val in try(var.defaults, {}) : key],
    [for key, val in try(var.instances, {}) : key],
  ))

  instances = flatten([
    for machine-type, instances in var.instances : [
      for instance-name, instance-config in instances : {
        id   = instance-config.id
        type = machine-type
        name = instance-name
        note = try(coalesce(instance-config.note, var.defaults[machine-type].note), "")

        node = coalesce(instance-config.node, var.defaults[machine-type].node)
        tags = distinct(coalesce(instance-config.tags, var.defaults[machine-type].tags))
        pool = try(coalesce(instance-config.pool, var.defaults[machine-type].pool, var.pool), "")

        image = coalesce(instance-config.image, var.defaults[machine-type].image, var.image)

        cpu        = coalesce(instance-config.cpu, var.defaults[machine-type].cpu)
        cpu-type   = coalesce(instance-config.cpu-type, var.defaults[machine-type].cpu-type)
        memory-mb  = coalesce(instance-config.memory-mb, var.defaults[machine-type].memory-mb)
        data-store = coalesce(instance-config.data-store, var.defaults[machine-type].data-store)
        disk-gb    = coalesce(instance-config.disk-gb, var.defaults[machine-type].disk-gb)

        network = {
          for key, _ in merge(var.defaults[machine-type].network, instance-config.network) :
          key => try(
            coalesce(try(instance-config.network[key], null), try(var.defaults[machine-type].network[key], null)),
            null
          )
        }

        args = {
          for key, _ in merge(var.template-args, var.defaults[machine-type].template-args, instance-config.template-args) :
          key => try(
            coalesce(try(instance-config.network[key], null), try(var.defaults[machine-type].network[key], null), try(var.template-args[key], null)),
            null
          )
        }

        machine-patch-template-path = coalesce(var.defaults[machine-type].machine-patch-template-path)
      }
    ]
  ])

  master-ips = [
    for instance in local.instances : instance.network["address-ipv4"] if contains(var.control-plane-types, instance.type)
  ]
}


resource "proxmox_virtual_environment_vm" "instances" {
  for_each = { for idx, instance in local.instances : instance.name => instance }

  name        = each.value.name
  vm_id       = each.value.id
  node_name   = each.value.node
  tags        = each.value.tags
  pool_id     = each.value.pool
  description = each.value.note


  started = true

  # stop_on_destroy = true
  timeout_stop_vm  = 10 * 60
  timeout_start_vm = 10 * 60


  agent {
    enabled = true
    timeout = "10m"
  }


  startup {
    order = 7
  }


  cpu {
    cores = each.value.cpu
    type  = each.value.cpu-type
    flags = [
      "+aes",
      "+pdpe1gb",
    ]
    numa = true # is required for hugepages
  }


  memory {
    dedicated = each.value.memory-mb
    # hugepages = "2"
    hugepages = "1024"
  }


  network_device {
    bridge      = try(each.value.network.interface, "")
    queues      = each.value.cpu
    mac_address = "32:90:${join(":", formatlist("%02X", split(".", try(each.value.network.address-ipv4, "0.0.0.0"))))}"
    firewall    = true
    vlan_id     = try(each.value.network.vlan, null)
  }


  scsi_hardware = "virtio-scsi-single"

  disk {
    file_id     = each.value.image
    file_format = "raw"
    interface   = "scsi0"
    size        = each.value.disk-gb
    ssd         = true
    iothread    = true
  }


  operating_system {
    type = "l26"
  }


  tpm_state {
    version      = "v2.0"
    datastore_id = each.value.data-store
  }


  lifecycle {
    ignore_changes = [
      started,
      # ipv4_addresses,
      # ipv6_addresses,
      # network_interface_names,
      initialization,
      cpu,
      memory,
      disk,
      clone,
      network_device,
    ]
  }
}


locals {
  instances-node = flatten([
    for _, instance in local.instances : [
      for node-name, vm in proxmox_virtual_environment_vm.instances : {
        instance = instance
        vm       = vm
      } if vm.name == instance.name
    ]
  ])
}


resource "proxmox_virtual_environment_firewall_options" "instances" {
  for_each = { for idx, instance in local.instances-node : instance.instance.name => instance }

  node_name = each.value.instance.node
  vm_id     = each.value.vm.id
  enabled   = false

  dhcp          = false
  ipfilter      = false
  log_level_in  = "nolog"
  log_level_out = "nolog"
  macfilter     = false
  ndp           = false
  input_policy  = "DROP"
  output_policy = "ACCEPT"
  radv          = true
}


resource "talos_machine_secrets" "this" {
  talos_version = var.version-talos
}


data "talos_machine_configuration" "master" {
  cluster_name     = var.cluster-name
  cluster_endpoint = "https://example.com:6443" # should be replaced by template file
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.version-talos
  kubernetes_version = var.version-k8s
}


data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster-name
  cluster_endpoint = "https://example.com:6443" # should be replaced by template file
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.version-talos
  kubernetes_version = var.version-k8s
}


data "talos_client_configuration" "this" {
  cluster_name         = var.cluster-name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.master-ips
}


resource "talos_machine_configuration_apply" "this" {
  for_each = { for idx, instance in local.instances-node : instance.instance.name => instance }

  node                        = [for ip in flatten(each.value.vm.ipv4_addresses) : ip if cidrhost(var.subnet, 0) == cidrhost("${ip}/${substr(var.subnet, -2, 2)}", 0)][0]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = contains(var.control-plane-types, each.value.instance.type) ? data.talos_machine_configuration.master.machine_configuration : data.talos_machine_configuration.worker.machine_configuration

  config_patches = [
    templatefile("${each.value.instance.machine-patch-template-path}", each.value.instance)
  ]

  depends_on = [proxmox_virtual_environment_vm.instances]
}


resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.master-ips[0]
}


resource "talos_cluster_kubeconfig" "this" {
  depends_on                   = [talos_machine_bootstrap.this]
  client_configuration         = talos_machine_secrets.this.client_configuration
  node                         = local.master-ips[0]
  certificate_renewal_duration = "24h"
}
