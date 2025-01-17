variable "subnet" {
  description = "(required) a subnet cluster nodes are to belong to, should be /24 network covering ips of vms, is required to correctly select node ip to apply machine configs"
  type        = string
}


variable "pool" {
  description = "(optional) pve pool id to add instances to, can be specified or overwritten either in pool, or defaults, or instances"
  type        = string
  default     = null
}


variable "cluster-name" {
  description = "(required) name of talos k8s cluster"
  type        = string
}


variable "image" {
  description = "(optional) default talos os image pve path including data store, must be specified either in image, or defaults, or instances, e.g `pve-images:iso/talos-1.9.1-metal-amd64.img`"
  type        = string
  default     = null
}


variable "version-talos" {
  description = "(optional) version of talos installer image to use"
  type        = string
  nullable    = true
  default     = null
}


variable "version-k8s" {
  description = "(optional) version of k8s components images to use, can be overwritten per machine patch"
  type        = string
  nullable    = true
  default     = null
}


variable "template-args" {
  description = "(optional) template args allow to pass additional arguments to a template, they can be accessed as `{ args._ }`, is merged with values form defaults and instances"
  type        = map(any)
  sensitive   = true
  default     = {}
}


variable "defaults" {
  description = "(required) the object providing configuration defaults for cluster nodes by instance type, can be used to set configuration to node groups"
  type = map(object({
    node : optional(string)
    pool : optional(string)
    tags : optional(list(string), [])
    note : optional(string)

    image : optional(string)

    cpu : optional(number, 2)
    cpu-type : optional(string, "x86-64-v2")
    memory-mb : optional(number, 4096)
    memory-hugepage-mb : optional(number, 0)
    data-store : optional(string, "local-lvm")
    disk-gb : optional(number, 16)

    network : optional(object({
      interface : optional(string)
      gateway-ipv4 : optional(string)
      vlan : optional(number)
    }))

    template-args : optional(map(any))
    machine-patch-template-path : string
  }))
}


variable "instances" {
  description = "(optional) the object providing individual instances configurations by type, by instance name. Can override defaults, complex props are merged"
  default     = {}
  nullable    = true
  type = map(
    map(object({
      id : optional(number)
      node : optional(string)
      tags : optional(list(string))
      pool : optional(string)
      note : optional(string)

      image : optional(string)

      cpu : optional(number)
      cpu-type : optional(string)
      memory-mb : optional(number)
      memory-hugepage-mb : optional(number)
      data-store : optional(string)
      disk-gb : optional(number)

      network : object({
        interface : optional(string)
        address-ipv4 : string
        gateway-ipv4 : optional(string)
        vlan : optional(number)
      })

      template-args : optional(map(any))
    }))
  )
}


variable "control-plane-types" {
  description = "(optional) an instance of type from the list is considered a control plane node thus gets control plane machine config applied, others get worker node machine config"
  type        = list(string)
  default = [
    "cp",
    "cps",
    "controlplane",
    "controlplanes",
    "control-plane",
    "control-planes",
    "master",
    "masters"
  ]
}
