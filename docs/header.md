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
- [ ] fined an alternative way to identify vm ip without required subnet specifying
