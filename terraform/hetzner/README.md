# Terraform for Hetzner

Starts one or multiple VM(s) on Hetzner cloud.

## Usage
*Tested with terraform version v0.13.5. Older versions of terraform might require the* hashicorp/hcloud *provider. This is tested with the* hetznercloud/hcloud *provider.*

You can control the VM creation from `variables.tf`. Make sure that the path to your public ssh key, that you want to send to the server is correct.

The ssh key will be added to the `root` user. 

Initialize terraform in this repository.

```
terraform init
```

To apply, run 

```
terraform apply -var='hcloud_token=<YOUR-API-TOKEN-HERE>'
```

You should see the ip address(es) of your vm(s) created.

To destroy, run

```
terraform destroy -var='hcloud_token=<YOUR-API-TOKEN-HERE>'
```

## Test

Check that your machine is accessible via `ssh root@host -i YOUR_KEY_FILE`. 

