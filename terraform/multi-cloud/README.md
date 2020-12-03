# "Identical" machines among cloud providers

We want to be able to deploy "identical" machines among different cloud
providers. Each cloud provider has their own system for images.

There are two approaches that came to mind:
1. use the same OS (e.g. `Debian 10`) but in the version that is provided by
   the cloud provider. use [cloud-init](https://cloud-init.io/) to configure 
   them.  -> **very** similar, but not actually the same
2. create custom images by using [packer](https://packer.io) and deploy them to 
   the cloud providers

## 1. Use same OS and cloud-init (preferred)
Currently we use `Debian` as our OS for the VMs. They provide `cloud-images`
which are the official Debian images customized for cloud deployment. They are
also always available as image choices at `AWS`, `Microsoft
Azure` and `Hetzner cloud`.

In terraform, a `filter` function can be used to find the most recent version. 
Luckily, all terraform providers provide that functionality:
* with `aws`, we can use `aws_ami` to filter, see [aws.tf](aws.tf)
* with `azure`, we can use `source_image_reference ` to filter, see
    [azure.tf](azure.tf)
* with `hcloud`, we can use `hcloud_image`, see [hetzner.tf](hetzner.tf)

By using these filters, we are able to spin up VMs all using the latest
officially available `Debian 10` image of each cloud provider. This way we 
already have very similar machines.

However, each cloud provider uses his own customizations, which can lead to 
problems especially when automating. One issue are the default usernames:

|provider|default login  | configurable |
|--|--|--|
| `aws` |  admin | only cloud-init|
| `azure` | specification required, anything **but** admin  |  yes |
| `hcloud` | root  | only cloud-init |

Although they all run debian cloud image, we can see the issue.  `hcloud` is 
using `root` ssh login, which should be **disabled** in any production 
environment as it poses security risks. Configurable here means if it is 
possible to pass a variable during terraform instance creation, as it is 
possible (and required) in `azure` using 
[admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine#admin_username)

To avoid this problem, we can use [cloud-init](https://cloud-init.io/). It 
allows to apply user data to instances, works cross-distro cross-platform and is 
supported by all major cloud providers.  [See 
Availability](https://cloudinit.readthedocs.io/en/latest/topics/availability.html)

For [story #87](https://app.clubhouse.io/thinkdeep/story/87/find-a-way-to-deploy-or-configure-virtual-machines-in-a-way-that-all-vms-on-the-different-providers-will-work-and-look-the)
I want to use the same user among all machines. [preconf.yml](./preconf.yml) 
includes the `cloud-init` specific tasks. In our case, we use the module 
`users`, to add a user, set ssh key, allow passwordless sudo and specify bash as 
the shell. The second module is `runcmd`, in which we use `sed` to configure our 
`sshd_config` to disable root login, disable password login and allow the newly 
created user. The terraform code to use the template and fill it with the 
correct values is in [cloud-init.tf](./cloud-init.tf). Having it in this file 
allows to use the same `cloud-init` file for all providers. It uses 
`var.username` and `var.public_key_path`, which you specify for terraform.
To pass the cloud init data to the machines:
* `aws`: use `user_data`
* `hcloud`: use `user_data`
* `azure`: use `template_cloudinit_config`, then use `custom_data`. Thanks 
    microsoft.


#### Deploy amongst clouds
With the files `aws.tf`, `azure.tf` and `hetzner.tf` the resources are
specified. Terraform will read all of those files and create the infrastructure
accordingly. For this deployment, I use a single `vars.tf` file that defines the
variables. This is done because e.g. for this use case I wanted all machines to
be reachable by using the same keys. Specify values for variables in your
preferred way, and run

```
terraform init
terraform apply
```

You should get one machine for each provider, and terraform will output their
respective ip addresses. (**NOTE:** azure isn't printing, I talked to amer, 
seems to be a feature rather than bug. use `terraform refresh` to also get ip 
for azure)

You should now be able to ssh with the same username and your specified 
`ssh-key`. Congrats!

#### Outlook
If we want to go even further, we can run `ansible` to ensure that they are 
configured correctly (e.g.  exactly version `2.x.x` of package x is installed 
among all). As they are using the same base OS, there *shouldn't* be problems 
between them. Out of scope for this story.

Possible Challenge with this approach: `proxmox` instance. The images will not 
automatically be available for `proxmox`, so we would need a way that a similar 
image can be used on instances started via `proxmox`. Generic debian cloud images can be found
[here](https://cloud.debian.org/images/cloud) and could be used for `proxmox`.


## 2. Create images with packer (exemplary)
We could use a base image and use `packer` to create our own private images that
are stored with the cloud provider. This way, we can be sure that the machines
will actually run the **same** image.  However, we would add another level of
complexity by introducing a new tool to our chain. In addition, we would need to
pay for the storage of those as well.

An example script for creating a `private ami` based on `Ubuntu 20.04` can be
seen in `packer/aws-ami.json`. Currently I only implemented `aws` as I prefer 
option 1. `packer` also allows to filter for `ami`, similar to how it is 
possible in `terraform`. This way we can always use the latest, officially 
created ubuntu image. Works the same way with debian.

To run the script, you must install [packer](https://www.packer.io/downloads).
As `packer` required your credentials to log in, you must make your tokens
available e.g. by using environment variables.

```
export AWS_ACCESS_KEY_ID="your_access_key_id"
export AWS_SECRET_ACCESS_KEY="your_secret_access_key"
```

You can then run
```
packer build aws-ami.json
```

Your custom image will now be available as a `private ami` for all your 
machines.
