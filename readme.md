# Proxmox talos cluster module

This module allows to declaratively create talos k8s cluster running inside Proxmox VE. Flexible configuration allows to overwrite parameters at multiple levels of setup giving fine grained modification controls. It creates vms, applies pve firewall rules, applies machine configs with patches and bootstraps a cluster.


## Usage

`main.tf`:

```hcl
module "pve-cluster-talos" {
  source = "github.com/deinsone/terraform-pve-talos-cluster.git"

  name   = "k8s-cluster-1"
  subnet = "10.0.0.0/24"

  defaults = {
    controlplane = {
      network = {
        interface    = "vmbr0"
        gateway-ipv4 = "10.0.0.1"
      }

      image                       = "local:iso/talos-1.9.1-metal.img"
      machine-patch-template-path = "${path.module}/controlplane.yaml.tpl"
    }
    # other custom types ...
  }

  instances = {
    controlplane = {
      k8s-cluster-cp-i1 = {
        node = "proxmox-i1"
        network = {
          address-ipv4 = "10.0.0.21"
        }
      }
    }
  }

  template-args = {
    nodes-subnet = "10.0.0.0/24"
    # other custom properties ...
  }
}
```


`controlplane.yaml.tpl`:

```yaml
machine:
  ...
  kubelet:
    nodeIP:
      validSubnets:
        - ${args.nodes-subnet}
  network:
    hostname: ${name}
    interfaces:
      - deviceSelector:
          physical: true
        addresses:
          - ${network.address-ipv4}/24
        dhcp: false
        routes:
          - gateway: ${network.gateway-ipv4}
    nameservers:
      - ${network.gateway-ipv4}
  ...
```


## Todo

- [ ] allow to specify storage drives array
- [ ] allow to specify network interfaces array
- [ ] allow to specify passthrough pcie devices array
- [ ] add more examples
- [ ] add [keep a changelog](https://keepachangelog.com/en/1.0.0/) document
- [ ] add gh release


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | 0.69.1 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.7.0 |


## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_firewall_options.instances](https://registry.terraform.io/providers/bpg/proxmox/0.69.1/docs/resources/virtual_environment_firewall_options) | resource |
| [proxmox_virtual_environment_vm.instances](https://registry.terraform.io/providers/bpg/proxmox/0.69.1/docs/resources/virtual_environment_vm) | resource |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.this](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/resources/machine_secrets) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/data-sources/client_configuration) | data source |
| [talos_machine_configuration.master](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/data-sources/machine_configuration) | data source |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster-name"></a> [cluster-name](#input\_cluster-name) | (required) name of talos k8s cluster | `string` | n/a | yes |
| <a name="input_control-plane-types"></a> [control-plane-types](#input\_control-plane-types) | (optional) an instance of type from the list is considered a control plane node thus gets control plane machine config applied, others get worker node machine config | `list(string)` | <pre>[<br/>  "cp",<br/>  "cps",<br/>  "controlplane",<br/>  "controlplanes",<br/>  "control-plane",<br/>  "control-planes",<br/>  "master",<br/>  "masters"<br/>]</pre> | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | (required) the object providing configuration defaults for cluster nodes by instance type, can be used to set configuration to node groups | <pre>map(object({<br/>    node : optional(string)<br/>    pool : optional(string)<br/>    tags : optional(list(string), [])<br/><br/>    image : optional(string)<br/><br/>    cpu : optional(number, 2)<br/>    cpu-type : optional(string, "x86-64-v2")<br/>    memory-mb : optional(number, 4096)<br/>    data-store : optional(string, "local-lvm")<br/>    disk-gb : optional(number, 16)<br/><br/>    network : optional(object({<br/>      interface : optional(string)<br/>      gateway-ipv4 : optional(string)<br/>      vlan : optional(number)<br/>    }))<br/><br/>    template-args : optional(map(any))<br/>    machine-patch-template-path : string<br/>  }))</pre> | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | (optional) default talos os image pve path including data store, must be specified either in image, or defaults, or instances, e.g `pve-images:iso/talos-1.9.1-metal-amd64.img` | `string` | `null` | no |
| <a name="input_instances"></a> [instances](#input\_instances) | (optional) the object providing individual instances configurations by type, by instance name. Can override defaults, complex props are merged | <pre>map(<br/>    map(object({<br/>      id : optional(number)<br/>      node : optional(string)<br/>      tags : optional(list(string))<br/>      pool : optional(string)<br/><br/>      image : optional(string)<br/><br/>      cpu : optional(number)<br/>      cpu-type : optional(string)<br/>      memory-mb : optional(number)<br/>      data-store : optional(string)<br/>      disk-gb : optional(number)<br/><br/>      network : object({<br/>        interface : optional(string)<br/>        address-ipv4 : string<br/>        gateway-ipv4 : optional(string)<br/>        vlan : optional(number)<br/>      })<br/><br/>      template-args : optional(map(any))<br/>    }))<br/>  )</pre> | `{}` | no |
| <a name="input_pool"></a> [pool](#input\_pool) | (optional) pve pool id to add instances to, can be specified or overwritten either in pool, or defaults, or instances | `string` | `null` | no |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | (required) a subnet cluster nodes are to belong to, should be /24 network covering ips of vms, is required to correctly select node ip to apply machine configs | `string` | n/a | yes |
| <a name="input_template-args"></a> [template-args](#input\_template-args) | (optional) template args allow to pass additional arguments to a template, they can be accessed as `{ args._ }`, is merged with values form defaults and instances | `map(any)` | `{}` | no |
| <a name="input_version-k8s"></a> [version-k8s](#input\_version-k8s) | (optional) version of k8s components images to use, can be overwritten per machine patch | `string` | `null` | no |
| <a name="input_version-talos"></a> [version-talos](#input\_version-talos) | (optional) version of talos installer image to use | `string` | `null` | no |


## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster-name"></a> [cluster-name](#output\_cluster-name) | name of talos k8s cluster |
| <a name="output_control-plane-types"></a> [control-plane-types](#output\_control-plane-types) | types of control planes |
| <a name="output_image"></a> [image](#output\_image) | default talos os image |
| <a name="output_instances"></a> [instances](#output\_instances) | snapshot of desired vms configurations, including overrides merged, includes sensitive template args |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | raw admin kubeconfig file of a provisioned cluster |
| <a name="output_pool"></a> [pool](#output\_pool) | pve pool id instances are added to |
| <a name="output_subnet"></a> [subnet](#output\_subnet) | a subnet cluster nodes are to belong to, should be /24 network covering ips of vms, is required to correctly select node ip to apply machine configs |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | raw talosconfig file of a provisioned cluster |
| <a name="output_template-args"></a> [template-args](#output\_template-args) | default template arguments passed to machine config patches |
| <a name="output_version-k8s"></a> [version-k8s](#output\_version-k8s) | default version of k8s components images used |
| <a name="output_version-talos"></a> [version-talos](#output\_version-talos) | version of talos installer image to use |
| <a name="output_vms"></a> [vms](#output\_vms) | provisioned proxmox vms of talos nodes |