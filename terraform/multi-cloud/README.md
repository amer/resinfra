# "Identical" machines among cloud providers

We want to be able to deploy "identical" machines among different cloud
providers. Each cloud provider has their own system for images.

There are two approaches that came to mind:
1. use the same OS (e.g. `Debian 10`) but in the version that is provided by
   the cloud provider -> similar, but not actually the same
2. create images by using [packer](https://packer.io) and deploy them to the
   cloud providers

## 1. Use same OS
Currently we use `Debian` as our OS for the VMs. They provide `cloud-images`
which are the official Debian images customized for cloud deployment. They are
also always available as image choices at `AWS`, `Microsoft
Azure` and `Hetzner cloud`.

A `filter` function can be used to find the most recent version. Luckily, all
terraform providers provide that functionality:
* with `aws`, we can use `aws_ami` to filter, see [aws.tf](aws.tf)
* with `azure`, we can use `source_image_reference ` to filter, see
    [azure.tf](azure.tf)
* with `hcloud`, we can use `hcloud_image`, see [hetzner.tf](hetzner.tf)

By using these filters, we are able to spin up VMs all using the latest
officially available `Debian 10` image of each cloud provider.

#### Deploy amongst clouds
With the files `aws.tf`, `azure.tf` and `hetzner.tf` the resources are
specified. Terraform will read all of those files and create the infrastructure
accordingly. For this deployment, I use a single `vars.tf` file that defines the
variables. This is done because e.g. for this use case I wanted all machines to
be reachable by using the same keys. Specify values for variables in your
preferred way, and run
```
terraform apply
```

You should get one machine for each provider, and terraform will output their
respective ip addresses. (**NOTE:** azure isn't printing, talked to amer)

**WIP**: ensure that all machines will have same default user, so we can avoid
specifying that

Then, we can run `ansible` to ensure that they are configured correctly (e.g.
exactly version `2.x.x` of package x is installed among all). As they are using
the same base OS, there *shouldn't* be problems between them.

Challenge with this approach: `proxmox` instance. The images will not be
available for `proxmox`, so we would need a way that a similar image can be used on
instances started via `proxmox`. Generic debian cloud images can be found
[here](https://cloud.debian.org/images/cloud) and could be used for `proxmox`.


## 2. Create images with packer
We could use a base image and use `packer` to create our own private images that
are stored with the cloud provider. This way, we can be sure that the machines
will actually run the **same** image.  However, we would add another level of
complexity by introducing a new tool to our chain. In addition, we would need to
pay for the storage of those as well.

An example script for creating a `private ami` based on `Ubuntu 20.04` can be
seen in `packer/aws-ami.json`. Currently I only implemented `aws`, might 
continue to add the other cloud providers, although I prefer option 1. `packer` 
also allows to filter for `ami`, similar to how it is possible in `terraform`. This way we can always use the latest, officially created ubuntu image.

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
