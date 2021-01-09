#!/bin/bash

cd ./terraform/multi-cloud

echo "-------------------------------------------"
echo "Welcome to the standalone deployment tool."
echo "-------------------------------------------"
echo ""
while [ "$createOrDestroy" != "create" ] && [ "$createOrDestroy" != "destroy" ]
        do 
                read -p "Do you want to create or destroy VMs?: (create/destroy) " createOrDestroy
done

if [ "$createOrDestroy" == "destroy" ]
	then
			terraform destroy
			exit
fi

while [ "$vm_dimension" != "large" ] && [ "$vm_dimension" != "small" ]
        do 
				echo ""
                echo ""
				echo "Current available VM dimensions/sizes/performance"
				echo "small: 1-2 vCPU and 1-3.5 GB RAM"
				echo "large: 4-8 vCPU and 16-32 GB RAM"
				echo ""
                read -p "Choose VM dimension (large/small): " vm_dimension
done

instances_count=0
while [ $instances_count -lt 1 ] || [ $instances_count -gt 9 ]
        do 
				echo ""
                read -p "Number of VMs to deploy: (1-9) " instances_count
done

# test if terraform is initialized
if [ ! -d .terraform ]
	then
		echo "Terraform is currently not initialized. I will try to do it for you"
		terraform init
fi

if [ ! -f terraform.tfvars ] 
	then
		echo "The file terraform.tfvars could not be found"
		exit
fi


read -p "Start the deployment process? (y/n): " apply

if [ "$apply" == "y" ]
	then
		echo "Deployment process starts."
	else 
		echo "Deployment process canceled!"
		exit
fi


timestamp=`date '+%m%d%y%H%M%S'`
if [ "$vm_dimension" == "large" ]
	then
			terraform apply -var-file="size_large.tfvars" -var "instances=${instances_count}" -auto-approve
			#terraform apply -var-file="size_large.tfvars" -var "instances=${instances_count}" -auto-approve > "terraform_planlog_${timestamp}.log"
elif [ "$vm_dimension" == "small" ]
        then
			terraform apply -var-file="size_small.tfvars" -var "instances=${instances_count}" -auto-approve
fi


# TODO: Error detection

echo ""
echo "-------------------------------------------------------------------"
echo "Your VM is deployed and the important information are shown below:"
echo "-------------------------------------------------------------------"
echo ""


terraform output
