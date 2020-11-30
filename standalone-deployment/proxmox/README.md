# Terraform for Proxmox
 
This is a Terraform configuration to clone and deploy a VM on a Proxmox server. Before you can use Terraform for this purpose you have to take some actions to pre-configure Proxmox.
 
## Network configuration
Virtual Machines need a Network where they can get deployed to, so that they are reachable from the host.
 
The example below represents our current working network configuration with one subnet (`10.1.0.1/24`) for the VMs and the host that is in the network `92.204.175.162/30`. The main network provided is /30 and has no IPs left for the VMs. (/30 = 3 IPs - 1 Gateway, 1 Boradcast, 1 Proxmox Server).
 
```
auto lo
iface lo inet loopback
 
iface enp1s0f0 inet manual
 
iface enp1s0f1 inet manual
# Default config
# The main networksegment is /30 and therefor has no ip left - VMs cant be reached when started on this interface as they have no valid ip 
auto vmbr0
iface vmbr0 inet static
        address 92.204.175.162/30
        gateway 92.204.175.161
        bridge-ports enp1s0f0
        bridge-stp off
        bridge-fd 0
 
# The new subnet for the VMs. 
# They have to be created with interface vmbr1, otherwise they are not reachable.
auto vmbr1
iface vmbr1 inet static
        address 10.1.0.1/24
        bridge-ports none
        bridge-stp off
        bridge-fd 0
        # Routes for routing the traffic to the host and make the VMs in this subnet accessible
        post-up echo 1 > /proc/sys/net/ipv4/ip_forward
        post-up   iptables -t nat -A POSTROUTING -s '10.1.0.1/24' -o vmbr0 -j MASQUERADE
        post-down iptables -t nat -D POSTROUTING -s '10.1.0.1/24' -o vmbr0 -j MASQUERADE
```
This solution is based on https://blog.jenningsga.com/private-network-with-proxmox/
 
## Third-party provider Telmate/proxmox
 
The proxmox provider is developed by a third party project available via https://github.com/Telmate/terraform-provider-proxmox/.
 
The proxmox provider was added to the Terraform provider list and can now be automatically installed by Terraform. Simply add the proxmox provider to the Terraform configuration file as shown in the example below
 
```
terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.6.5"
    }
  }
  required_version = ">= 0.13.5"
}
```
and when running `terraform init` the provider should get automatically downloaded and installed.
## Defining the Deployment
### Create a Virtual Machine
#### Create a template
Unlike other providers, there are no predefined images for the virtual machines. We have to create our own templates of the images, that we want do deploy afterwards via Terraform.
The easiest way is to adopt the debian openstack image, as it is ready for e.g. the configuration via cloud init.
Just follow the instructions from the "Creating a template" section of https://yetiops.net/posts/proxmox-terraform-cloudinit-saltstack-prometheus/#what-about-other-distributions or create it via the GUI of proxmox.
#### Terraform configuration
If we have our template we can clone it to create virtual machines. Be aware that a lot of the examples from https://github.com/Telmate/terraform-provider-proxmox/blob/master/examples/ and nearly all other sources i found are not working correctly out of the box. It seems as there where a few changes recently to this provider.
 
https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/vm_qemu.md containing a list of the arguments you can use for the terraform configuration file. Some of them are leading to errors. E.g. the disk id that is also marked as "required" when using the disk argument is not allowed and outputs errors when executing `terraform plan`.
 
Some of the configuration values are highly dependent on the used template machines. E.g. disk id of the correct boot device.
 
Also there are configurations that have to be done on the node or pool level of proxmox e.g. allow communication in an defined subnet.
 
### Creating a Container
For the most cases a lxc container would be the best solution, but currently i was not able to get container running via terraform. The terraform apply process is crashing with the message:
```
!!!!!!!!!!!!!!!!!!!!!!!!!!! TERRAFORM CRASH !!!!!!!!!!!!!!!!!!!!!!!!!!!!
 
Terraform crashed! This is always indicative of a bug within Terraform.
A crash log has been placed at "crash.log" relative to your current
working directory. It would be immensely helpful if you could please
report the crash with Terraform[1] so that we can fix this.
 
When reporting bugs, please include your terraform version. That
information is available on the first line of crash.log. You can also
get it by running 'terraform --version' on the command line.
 
SECURITY WARNING: the "crash.log" file that was created may contain 
sensitive information that must be redacted before it is safe to share 
on the issue tracker.
 
[1]: https://github.com/hashicorp/terraform/issues
 
!!!!!!!!!!!!!!!!!!!!!!!!!!! TERRAFORM CRASH !!!!!!!!!!!!!!!!!!!!!!!!!!!!
```
I tried a few examples I found on the internet but all configurations led to the same crash.
 
## Running the deployment
Enter the directory where the `variable.tf` and `main.tf` files are located. 
Change the `variables.tf` according to your setup. Initialize Terraform: 
``` 
terraform init 
```
 
Then plan the terraform run with
 
```
terraform plan
```
 
and run it with 
 
```
terraform apply
```
 
Connect to the deployed VMs via 
```
ssh root@host -i YOUR_KEY_FILE
 
e.g.:
ssh root@192.168.2.201 -i ~/.ssh/id_rsa
```
 
## Teardown
Afterwards you can destroy all deployed resources with 
 
```
terraform destroy
```
 
## Debugging
Use the proxmox web GUI to have a look at what the machine is currently doing and if the VM was deployed correctly.
 
Sometimes `TF_LOG=DEBUG terraform plan` can help to identify problems.


