# "Identical" machines among cloud providers

We want to be able to deploy "identical" machines among different cloud
providers. Each cloud provider has their own system for images.

There are two approaches that came to mind:
1. use the same OS (e.g. `Ubuntu 20.04`) but in the version that is provided by
   the cloud provider -> similar, but not actually the same
2. create images by using [packer](https://packer.io) and deploy them to the
   cloud providers

## 1. Use same OS
Currently we use `Ubuntu` as our OS for the VMs. They provide `cloud-images`
which are the official Ubuntu images customized for cloud deployment. They are
also always available as image choices at `AWS`, `Google cloud` and `Microsoft
Azure`. Using the [Ubuntu Cloud Image
Finder](https://cloud-images.ubuntu.com/locator/) you can get the image `ID`
that they can be found under the cloud provider. (e.g. `ami-XXX` for `aws`)
Accodring to the cloud-image webpage, these images will indeed be the same
amongst cloud providers (given same version/release)

We could write a little script that fetches the correct id for each
cloudprovider and feed `terraform` accordingly. Alternatively, the `filter`
function can be used to find the most recent version. Then, we can run `ansible`
to ensure that they are configured correctly.  As they are using the same base
OS, there *shouldn't* be problems between them.

Problem with this approach: `proxmox` instance. The images will not be available
for `proxmox`, so we would need a way that a similar image can be used on
instances started via `proxmox`. Generic Ubuntu cloud images can be found
[here](https://cloud-images.ubuntu.com/) and could be used for `proxmox`.


## 2. create images with packer
We could use a base image and use `packer` to create our own private images that
are stored with the cloud provider. This way, we can be sure that the machines
will actuallry run the **same** image.  However, we would add another level of
complexity by introducing a new tool to our chain.

An example script for creating a `private ami` based on `Ubuntu 20.04` can be
seen in `aws-ami.json`. Currently I only implemented `aws`, will continue to add
the other cloud providers. `packer` also allows to filter for `ami`, similar to
how it is possible in `terraform`. This way we can always use the latest,
officially created ubuntu image.

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
