# What is this?
 
This Linux shell script can deploy Virtual Machines across the cloud providers Amazon Web Services, Azure, Hetzner Cloud and Proxmox Servers. The Virtual Machines running in a standalone mode and are not automatically connected to each other. You have limited customization options for the Virtual Machines (e.g. the performance of the VM (high amount of CPU cores and RAM, low amount of CPU cores and RAM)). In the end the public IP-Address of the newly created Virtual Machine will get displayed along with the login credentials. 

For further information have a look at the README.md files in the provider subdirectories.
 
# Usage
 
Execute the bash script and follow the instructions on the console
 
``` 
chmod +x standalone-deployment.sh
./standalone-deployment.sh 
```
 
# Prerequisites
## Authentication Data
In order to deploy machines, this script needs access to your cloud accounts. Therefore, an account on AWS, Azure and Hetzner Cloud is needed, as well as the login information for a Proxmox user that has the required permissions. In the most cases you have to create a specific access token. Please use the specific cloud provider documentation on how to create these.
 
Populate the `secret.tfvars` with your credentials. See the `secret.tfvars.example` files as examples.
 
## Dependencies
You have to install the following dependencies:
* sudo curl gnupg gnupg2 gnupg1 software-properties-common git
* [go](https://linuxize.com/post/how-to-install-go-on-debian-10/)
* [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* [azure cli](https://docs.microsoft.com/de-de/cli/azure/install-azure-cli-apt)
* [ansible >= 2.10](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
 
# Limitations
* Currently there is no support to destroy the created resources. Use `terraform destroy -var-file="secret.tfvars"` in the provider subdirectory to destroy the resources.
* Currently there is no support for creating more than one VM per provider.
* Currently there is no support for further management of the created VMs.
* Currently there is no support for further configuration through the script. Have a look at the Terraform configuration files to change things.
* The Proxmox VM is not accessible via a public ip afterwards because limitations by the provider

# Know Bugs
* Some IP outputs dont work correctly
* When deploying AWS VMs the Ansible run crashes
