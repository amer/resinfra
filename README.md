# Building Resilient Infrastructure by Spanning Clouds
This is the repository for the project "Building Resilient Infrastructure by Spanning Clouds", which was developed as part of the module "Advanced Distributed System Prototyping" at the Technical University Berlin in the winter semester 2020/2021.

The main goal of this project is to build a more resilient infrastructure by spanning
clouds. To achieve this goal, we deploy virtual machines across different cloud providers and connect them together. Afterwards, we deploy monitoring solutions and create watchdogs that ensure that failed infrastructure is re-created.

## How to run it?
Ensure all images are built and ready. For more information see [the packer directory](packer).
Create and populate a ``terraform/terraform.tfvars`` file. Use 
[terraform.tfvars.example](terraform/terraform.tfvars.example) as a template. 

To build the entire infrastructure:
```
$ cd terraform 
$ terraform apply
```

For more information refer to the [infrastructure README](terraform/README.md).

## How does it work?
For the automatic deployment of the infrastructure we use a tool called [Terraform](https://www.terraform.io/). 
After we deployed the infrastructure, we use [Ansible](https://www.ansible.com/) to deploy the application on top 
of the infrastructure.