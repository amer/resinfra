# What is this?
This is a terraform manifest which will create and set up a resource group, virtual network, 
internal subnet, network interface, network security group, public IP, and a Linux virtual machine, public DNS zone and DNA 'A' recored in Azure cloud.

After running the manifest, you can ssh to the virtual machine using the public IP address. 
Use `terraform output fqdn` to get the fqdn.

The manifest will copy the public key in `~/.ssh/id_rsa.pub` to the target virtual machine.

To ssh to the virtual machine use:
```
$ ssh adminuser@fqdn
```

## Quick start

### Requirements
Make sure you have Azure CLI tool and Terraform installed. 

#### To install on Mac OS
```
$ brew install azure-cli terraform
```

### Login
This command will take you to the browser to login.
```
$ az login
```

### Create service principal client | Azure cli
[ref](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
[built in roles](https://docs.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles)
```bash
$ az account list --output table
$ az account set --subscription="$RESINFRA_SUBSCRIPTION_ID"
$ az ad sp create-for-rbac --name YourServicePrincipalName --role="Contributor" --scopes="/subscriptions/$RESINFRA_SUBSCRIPTION_ID"
```

The output should look something like this. Use these values to populate env.sh and variables.tfvars.
```
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "YourServicePrincipalName",
  "name": "http://YourServicePrincipalName",
  "password": "xxxxxxxxxxxxxxxxxxx",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

### Create your initial configuration | Terraform
[terraform/azure-build](https://learn.hashicorp.com/tutorials/terraform/azure-build)

```bash
$ terraform init
$ terraform plan
$ terraform apply
$ terraform show
$ terraform state list
```

### Save and apply a plan example
``` 
$ terraform plan -out=MyplanfileName
$ terraform apply "MyplanfileName"
```

### Show output example

```
$ terraform output public_ip_address
```

### About topologies | Resources
https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks/secure-baseline-aks
https://github.com/mspnp/aks-secure-baseline
https://kops.sigs.k8s.io/