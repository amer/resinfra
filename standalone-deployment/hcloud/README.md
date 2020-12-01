# Terraform for Hetzner

Starts one or multiple VM(s) on Hetzner cloud.

Optional:
- create and assign floating ips to each of the created vms.
- create and assign volumes to each of the created vms. 

## Usage
*Tested with terraform version v0.13.5. Older versions of terraform might require the* hashicorp/hcloud *provider. This is tested with the* hetznercloud/hcloud *provider.*

### Options
You can control the VM creation as well as the creation and assigning of floating ips and volumes by setting varialbes accordingly in your `terraform apply -var='VAR_NAME=VALUE'` command.

| variable           | default           | description                                                                                                       |
|--------------------|-------------------|-------------------------------------------------------------------------------------------------------------------|
| hcloud_token       | null              | Your Hetzner cloud api token                                                                                      |
| pub_ssh_path       | ~/.ssh/id_rsa.pub | Path to the public ssh key that will be added to all vms created. The ssh key will be added to the  `root`  user. |
| enable_volume      | false             | Set `true` to create, assign and mount a volume on all vms created                                                |
| enable_floating_ip | false             | Set `true` to create and assign a floating ip address for all vms created                                         |
| location           | nbg1              | Hetzner region on where to deploy                                                                                 |
| instances          | 1                 | Number of vms to create                                                                                           |
| server_type        | cx11              | Hetzner server type                                                                                               |
| image              | ubuntu-20.04      | Image to use                                                                                                      |
| volume_size        | 100               | Size of the volume that is to be mounted                                                                          |

### Apply
Initialize terraform in this repository.

```
terraform init
```

To apply, run 

```
terraform apply -var-file="secret.tfvars"
```

The output should provide with the ip and id of the vm(s) as well as the ip of the floating ip and the directory onto which volumes have been mounted.

To destroy, run

```
terraform destroy -var-file="secret.tfvars"
```

## Test

Check that your machine is accessible via `ssh root@host -i YOUR_KEY_FILE`. 

### Note on using floating ips
If you chose to create and assign a floating ip, you will have to add it to the network interface config of your machine. Refer to the [docs](https://docs.hetzner.com/cloud/floating-ips/persistent-configuration/) for more information.