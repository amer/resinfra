# Building Resilient Infrastructure by Spanning Clouds

This is the repository for the project "Building Resilient Infrastructure by Spanning Clouds", which was developed as 
part of the module "Advanced Distributed System Prototyping" at the Technical University Berlin in the winter semester 
2020/2021.

The main goal of this project is to build a more resilient infrastructure by spanning clouds. To achieve this goal, we 
deploy virtual machines across different cloud providers and connect them together. Afterwards, we deploy monitoring 
solutions and create watchdogs that ensure that failed infrastructure is re-created.

## How does it work?

For the automatic deployment of the infrastructure we use a tool called [Terraform](https://www.terraform.io/). We build the infrastructure based on custom linux images that we build with [Packer](https://www.packer.io/).
After we deployed the infrastructure, we use [Ansible](https://www.ansible.com/) to deploy the application on top
of the infrastructure.

## How to run it?

### Required software

First, install the following software on your machine:

- [Hashicorp](https://www.hashicorp.com/) Terraform and Packer
- [Ansible](https://docs.ansible.com/ansible/2.5/installation_guide/intro_installation.html)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

### Setting up projects on each provider

We support Azure, GCP, Hetzner Cloud, and Proxmox. 

- On Azure, create a subscription (or re-use an existing one) and a resource group.
- On GCP and Hetzner Cloud, create a project.

For each provider, generate the required credentials and put them in 
[`terraform/terraform.tfvars`](terraform/terraform.tfvars) and [`packer/packer-vars.json`](packer/packer-vars.json). 
There are guides available on how to generate credentials for 
[Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli), 
[GCP](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#adding-credentials), and 
[Hetzner](https://docs.hetzner.cloud/). For GCP, instead of setting an environment variable to the path of the 
service account JSON, add the path to the following three configuration files:

- [`terraform/terraform.tfvars`](terraform/terraform.tfvars)
- [`terraform/main.tf`](terraform/main.tf)  
- [`packer/packer-vars.json`](packer/packer-vars.json)

### Building images

Ensure all images are built and ready. In short,

```
$ cd packer
$ for file in */*.pkr.hcl; do packer build -var-file=packer-vars.json "$file"; done
```

This step will not need to be run again until you change any of the images. For more information refer to the [packer readme](packer/README.md).

### Deploying

Deploy _everything_: 

```
$ cd terraform
$ terraform init
$ terraform apply
```

`terraform init` is usually only needed before deploying for the very first time. For more information refer to the 
[infrastructure README](terraform/README.md).

### Accessing the deployed application

The application is now deployed on several worker VMs spread across different cloud providers. You should be able to 
access it through any of their public IP addresses.
