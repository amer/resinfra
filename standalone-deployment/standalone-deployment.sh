#!/bin/bash

while [ "$vm_dimension" != "large" ] && [ "$vm_dimension" != "small" ]
        do 
                read -p "Choose VM dimension (large/small): " vm_dimension
done

while [ "$provider" != "aws" ] && [ "$provider" != "azure" ] && [ "$provider" != "hcloud" ] && [ "$provider" != "proxmox" ]
        do 
                read -p "Choose one cloud provider for VM deployment (aws/azure/hcloud/proxmox): " provider
done

###################################################
# 	Some provider specific things		  #
###################################################

if [ "$provider" == "aws" ]
	then
		cd ./aws
fi

if [ "$provider" == "azure" ]
	then
		cd ./azure
fi

if [ "$provider" == "hcloud" ]
	then
		cd ./hcloud
fi

if [ "$provider" == "proxmox" ]
	then
		echo "Make sure you have configured your proxmox server correctly and updated the config files in ./proxmox/ acording to your configuration."
		read -p "Choose the network CIDR of the new VM. Example: 10.1.0.101/24 Warning: There is no conflict checking. Make sure to use only valid IP addresses: " proxmox_vm_cidr
		read -p "Choose the gateway of the new VM. Example: 10.1.0.1 Warning: Has to be valid: " proxmox_vm_gateway
		read -p "Choose the hostname of the new VM. Has to be unique. Warning: There is no conflict check: " proxmox_vm_name
		cd ./proxmox
fi

# we should be now in the directory of the provider. We have now to test if terraform is already initialized for this provider.
if [ ! -d .terraform ]
	then
		echo "Terraform is currently not initialized for this provider. I will try to do it for you"
		terraform init
fi

if [ ! -f secret.tfvars ] 
	then
		echo "The file secret.tfvars could not be found"
		exit
fi


echo "Plan the deployment"

if [ "$vm_dimension" == "large" ]
	then
		case "$provider" in 
			"aws") terraform plan -var-file="secret.tfvars" -var-file="aws_large.tfvars" -out "plan"
			;;
			"azure") terraform plan -var-file="secret.tfvars" -var-file="azure_large.tfvars" -out "plan"
			;;
			"hcloud") terraform plan -var-file="secret.tfvars" -var-file="hcloud_large.tfvars" -out "plan"
			;;
			"proxmox") terraform plan -var-file="proxmox_server.tfvars" -var-file="proxmox_large.tfvars" -var-file="secret.tfvars" -var "proxmox_vm_cidr=$proxmox_vm_cidr" -var "proxmox_vm_name=$proxmox_vm_name" -var "proxmox_vm_gateway=$proxmox_vm_gateway" -out "plan"
			;;
		esac

elif [ "$vm_dimension" == "small" ]
        then
                case "$provider" in 
			"aws") terraform plan -var-file="secret.tfvars" -var-file="aws_small.tfvars" -out "plan"
			;;
			"azure") terraform plan -var-file="secret.tfvars" -var-file="azure_small.tfvars" -out "plan"
			;;
			"hcloud") terraform plan -var-file="secret.tfvars" -var-file="hcloud_small.tfvars" -out "plan"
			;;
			"proxmox") terraform plan -var-file="proxmox_server.tfvars" -var-file="proxmox_small.tfvars" -var-file="secret.tfvars" -var "proxmox_vm_cidr=$proxmox_vm_cidr" -var "proxmox_vm_name=$proxmox_vm_name" -var "proxmox_vm_gateway=$proxmox_vm_gateway" -out "plan"
			;;
		esac
fi


read -p "Should the plan be applied? (y/n): " apply

if [ "$apply" == "y" ]
	then
		echo "Plan will be applied."
		terraform apply plan
	else 
		echo "Deployment process canceled!"
		exit
fi

# TODO: Error detection


echo "Your VM is deployed and the important information are shown below:"
case "$provider" in 
        "aws")
		echo "IP: $(terraform output public_ip)"
		echo "Username: ubuntu"
		echo "Password: disabled"
		echo "Login using the defined ssh_key"
        ;;
        "azure")
                echo "IP: $(terraform output public_ip_address)"
                echo "Username: adminuser"
                echo "Password: disabled"
                echo "Login using the defined ssh_key"
        ;;
        "hcloud")
        	echo "IP: $(terraform output vm_ips)"
		echo "Username: root"
		echo "Password: disabled"
		echo "Login using the defined ssh_key"
	;;
        "proxmox") 
		echo "IP: currently not supported"
		echo "Username: root"
		echo "Password: disabled"
		echo "Login using the defined ssh_key"
        ;;
esac

