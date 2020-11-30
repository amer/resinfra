variable resinfra_client_id {}
variable resinfra_client_secret {}
variable resinfra_subscription_id {}
variable resinfra_tenant_id {}
variable "resinfra_vm_size" {
	description = "Size of VM. Default: Standard_DS1_v2 # Specs of Standard_DS1_v2 vm: (vCPU: 1, Memory: 3.5 GiB, Storage (SSD): 7 GiB)"
	default = "Standard_DS1_v2"
}

