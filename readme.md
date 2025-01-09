# Proxmox talos cluster module

>> In progress . . .

```hcl
module "pve-cluster-talos" {
  source = "modules/pve-cluster-talos"

  cluster-name = "k8s-talos-1"
  image        = "local:iso/talos-1.9.1-metal-amd64-base.img"

  subnet = "10.0.0.0/24"
  region = "pve-cluster-1"

  defaults = {
    controlplane = {
      machine-patch-template-path = "${path.module}/templates/controlplane.yaml.tpl"
    }
    worker = {
      machine-patch-template-path = "${path.module}/templates/worker.yaml.tpl"
    }
  }

  instances = {
    controlplane = {
      k8s-talos-master-i1 = {
        node = "proxmox-i1"
        network = {
          interface    = "local"
          address-ipv4 = "10.0.0.20"
        }
      }
    }
    worker = {
      k8s-talos-worker-i1 = {
        node = "proxmox-i1"
        network = {
          interface    = "local"
          address-ipv4 = "10.0.0.21"
        }
      }
    }
  }
}
```

## Requirements

|---| ---|
|Providers|Version|
|---| ---|
| [proxmox](https://registry.terraform.io/providers/bpg/proxmox) | >= 0.69.1 |
| [talos](https://registry.terraform.io/providers/siderolabs/talos) | >= 0.7.0 |


- [ ] https://github.com/terraform-docs/terraform-docs
