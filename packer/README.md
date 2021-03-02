# Building images with packer

We are using packer to pre-build the images that will be used to spawn the specific machine types
that are part of the resinfra project.

All machines are preconfigured to the largest extent, allowing for a more sleek terraform script.

**The internal ip address of the consul leader node as well as the vpc cidr of the overall vpc need to be hardcoded.**
You can set these values in the ``packer-vars.json``.

## Available images
The following images can be built:
- gateway images:
  - Hetzner snapshot with ``hetzner-gateway-vm`` label
  - Proxmox clone named ``proxmox-gateway-vm``   
- deployer / resinfra images:
  - Hetzner snapshot with ``hetzner-deployer`` label
  - Hetzner snapshot with `hetzner-benchmark` label. Similar to ``hetzner-deployer`` but based on Ubuntu 20.04 LTS
- worker vm images:
  - Azure image ``azure-worker-vm`` in the respective resource group
  - GCP image with name ``gcp-worker-vm``
  - Hetzner snapshot with ``hetzner-worker-vm`` label
  - Proxmox clone named ``proxmox-worker-vm``
  
Images are built according to the respective packer files found in this folder. For all system components, we use Debian
10 as the base image. All images are built so that new 
machines seamlessly integrate into the final product. The central tool is Consul, which collects all nodes and publishes
their information to other services and tools used (such as prometheus).

## Build images
To build an image, populate the `packer-vars.json` file according to `packer-vars.json.example`.
Then, run the packer script that builds the respective image.

```
$ packer build -var-file=packer-vars.json -force worker-vms/worker-vm-gcp.pkr.hcl
```
The `-force` flag will ensure that existing images with the same name are being replaced. 

## Caveates
Building clones (images) on Proxmox does not work currently as machines created will not be accessible over ssh 
(they lack a public ip address) and there seems to be no way to implement that with the current proxmox packer
package. As a workaround, clones on proxmox are currently built manually.
