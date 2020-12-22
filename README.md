# Building Resilient Infrastructure by Spanning Clouds
This is the repository for the project "Building Resilient Infrastructure by Spanning Clouds", which was developed as part of the module "Advanced Distributed System Prototyping" at the Technical University Berlin in the winter semester 2020/2021.

The main goal of this project is to build a more resilient infrastructure by spanning
clouds. To achieve this goal, we deploy virtual machines across different cloud providers and connect them together. Afterwards, we deploy monitoring solutions and create watchdogs that ensure that failed infrastructure is re-created.

## How to run it?
In this early stage, we can only provide a simple prototype to automatically deploy vms across the cloud providers AWS, Azure, Hetzner Cloud and a private cloud provider that uses Proxmox. These VMs are only connected when created on the same provider. Connection between cloud providers is currently not implemented.

Start by populate the file `terraform.tfvars` in `/terraform/multi-cloud` with your login credentials for the different providers.

Run the shell script `standalone_depolyment.sh` in the root directory of this repository and follow the instructions on the console.

## How does it work?
For the automatic deployment of the infrastructure we use a tool called [Terraform](https://www.terraform.io/). After we deployed the infrastructure, we use [Ansible](https://www.ansible.com/) to deploy the application on top of the infrastructure.

For a more detailed description see our wiki and or project report (not finished currently)