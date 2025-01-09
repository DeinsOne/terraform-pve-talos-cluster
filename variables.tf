
variable "region" {
  description = "Region of a cluster, used for topology aware routing and csi. Can be name of a pve cluster or rack, or location"
  type        = string
}


variable "subnet" {
  description = "A subnet cluster nodes are to belong to"
  type        = string
}


variable "pool" {
  description = "Pve pool id to add instances to"
  type        = string
  default     = null
}


variable "cluster-name" {
  description = "Name of talos k8s cluster in talosconfig"
  type        = string
}


variable "image" {
  description = "Talos os image pve path including data store"
  default     = "pve-images:iso/talos-1.9.1-metal-amd64-base.img"
  type        = string
}


variable "version-talos" {
  type     = string
  nullable = true
  default  = null
}


variable "version-k8s" {
  type     = string
  nullable = true
  default  = null
}


variable "template-args" {
  description = "Template args allow to pass additional arguments to a template, they can be accessed as { args._ }"
  type        = map(any)
  default     = {}
}


variable "defaults" {
  description = "The object providing configuration defaults for instances by instance type"
  sensitive   = false
  default     = {}
  type = map(object({
    node : optional(string)
    tags : optional(list(string))
    pool : optional(string)

    image : optional(string)

    # refer to https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#type
    cpu : optional(number)        # 2
    cpu-type : optional(string)   # x86-64-v2
    memory-mb : optional(number)  # 4096
    data-store : optional(string) # local-lvm
    disk-gb : optional(number)    # 16

    # (required) the path should be relative to main terraform dir
    machine-patch-template-path : string
  }))
}


variable "instances" {
  description = "The object providing individual instances configurations by type, by instance name. Can override defaults"
  sensitive   = false
  default     = {}
  type = map(
    map(object({
      id : optional(number)
      node : string
      tags : optional(list(string))
      pool : optional(string)

      image : optional(string)

      cpu : optional(number)        # 2
      cpu-type : optional(string)   # x86-64-v2
      memory-mb : optional(number)  # 4096
      data-store : optional(string) # local-lvm
      disk-gb : optional(number)    # 16

      network : object({
        interface : string
        address-ipv4 : string
        gateway-ipv4 : optional(string)
      })
    }))
  )
}
