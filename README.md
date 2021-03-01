# Building Resilient Infrastructure by Spanning Clouds

This is the repository for the project "Building Resilient Infrastructure by Spanning Clouds", which was developed as 
part of the module "Advanced Distributed System Prototyping" at the Technical University Berlin in the winter semester 
2020/2021.

The main goal of this project is to build a more resilient infrastructure by spanning clouds. To achieve this goal, we 
deploy virtual machines across different cloud providers and span a single network over all of them. Afterwards, we deploy monitoring 
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
- (optional) [Google Cloud CLI] (https://cloud.google.com/sdk/docs/quickstart)

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

### Setting up remote terraform state storage

By default, the terraform state is stored in a bucket on GCP. This is required to make use of our system's self-healing capabilities, and a best practice for production deployments using terraform. For most development tasks, it is ok to delete the `backend` block in [`terraform/main.tf`](terraform/main.tf). For other use cases, follow the instructions:

1. [Create a bucket](https://console.cloud.google.com/storage/create-bucket) in your GCP project. 
2. Make sure that your GCP service account has read / write permission for it. 
3. Edit the bucket name in [`terraform/main.tf`](terraform/main.tf), commit and push.

Keep in mind that bucket names are globally unique – if you want to collaborate with others, you have two options. For produciton, we recommend to let everyone's service accounts access the same bucket. For development and testing, everyone can create their own buckets, edit the [`terraform/main.tf`](terraform/main.tf), but not commit the changes.

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
access it through any of their public IP addresses. The IP addresses are displayed at the end of `terraform apply`.
