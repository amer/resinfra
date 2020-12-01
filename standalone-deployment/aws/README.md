# Terraform and Ansible nginx setup on AWS

Setup an AWS ec2 instance using `terraform`. This instance is then going to be 
provisioned by `ansible` using a `playbook` to run an `nginx` docker container. 
It will run via `http` and thus is accessible via port `80`.

## Prerequisites

To run this example, you must ensure that the following tools are installed 
correctly.
* `terraform` version >=0.12
* `ansible` version >=2.0 -- [installation guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Configuration

To pass your AWS credentials to `terraform` in a safer way than hard coding it 
and distributing it to VCS, it is easier and more secure to use env variables.

Set the following environment variables and terraform will pick them up 
automatically:

```
export AWS_ACCESS_KEY_ID="your_access_key_id"
export AWS_SECRET_ACCESS_KEY="your_secret_access_key"
```

### Configuring terraform

You can configure the terraform deployment using the following variables:

| VARIABLE         | DEFAULT                 | DESCRIPTION
|------------------|-------------------------|-------------------------------------------------------------------------|
| region           | `eu-central-1`          | AWS region for resources to be created                                  |
| ami              | `ami-0502e817a62226e03` | AMI for instance to be created                                          |
| instance_type    | `t2.micro`              | AWS ec2 instance type , default is 1vCPU, 1GB RAM                       |
| public_key_path  | `~/.ssh/id_rsa.pub`     | path to your public key, will be baked into instance                    |  |
| private_key_path | `~/.ssh/id_rsa`         | path to your private key, used to access instances                      |
| remote_user      | `ubuntu`                | User for ssh connection. On aws, root is disable, use `ubuntu` instead. |

You can pass your values by running e.g. `terraform apply 
-var='public_key_path=~/.ssh/aws_key.pub`. 

I *personally* prefer handling terraform variables in the `terraform.tfvars` 
file.  In this file you specify the values for the variables defined in 
`vars.tf`. If the file `terraform.tfvars` exists, terraform will automatically 
load the values from it. This way you can avoid having to passing lots of 
variables via the command line.

Here is an example `terraform.tfvars` file (should be part of `.gitignore`!)

```
region="eu-central-1"
ami="ami-0502e817a62226e03"
instance_type="t2.small"
public_key_path="~/.ssh/aws_key.pub"
private_key_path="~/.ssh/aws_key"
```

While it would be possible to also configure all variables related to `ansible` 
in this file, I opted for a cleaner solution that separates the variables to 
make it easier to reuse.  All terraform variables are defined via the `vars.tf` 
file. 

**NOTE**: the reason we pass `private_key_path` here is that we use that key to 
ensure our ec2 instance is ready for ssh connections. Once ssh is ready, 
terraform will start the ansible playbook *automatically* and passes the private 
key to it. This way, it is not required to specify the key in `ansible.cfg` - 
more details are explained in the next section.

### Configuring ansible

Ansible should be configured using the `ansible.cfg` file. There are only a few 
variables that we need to declare.

| VARIABLE          | STATUS   | VALUE           | DESCRIPTION                                                                                                                                                                                                        |
|-------------------|----------|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| remote_user       | optional | `ubuntu`        | User for SSH connection. On this image on `aws`, root ssh is disabled and we use `ubuntu` instead. Declared as *optional*, as terraform is already passing the remote user when it is running the playbook for us.
| private_key_file  | optional | `/path/to/key/` | Specify private key for ansible to use.  Declared as *optional*, as in our example terraform is automatically passing this vaule.
| host_key_checking | required | `False`         | When connecting for the first time, ssh will prompt if we want to continue connecting even though authenticity of host can't be established. For automating this process, we need to disable that prompt.
| become            | required | `True`          | Set to true to enable privilege escalation (required for ansible e.g.  to install software). You can read more [here](https://docs.ansible.com/ansible/latest/user_guide/become.html)
| become_method     | required | `sudo`          | Method to use for privilege escalation.

I explicitly listed all variables here in `ansible.cfg` although for this 
example it is not required due to automatically passing variables from terraform 
to the ansible playbook to automate the whole process. However, to reuse the 
ansible playbook we have here, one can simply use `playbook.yaml` and 
`ansible.cfg` and use it somewhere else. 


## Running it

After configuring, you have to initialize terraform
```
terraform init
```

To apply, run

```
terraform apply -var-file="secret.tfvars"
```

If you did not use the `terraform.tfvars` method, you should pass variables 
using the `-var` style.  

`teraform apply` will do the following:
1. create key pair, security group, ec2 instance
2. wait for ssh to get ready
3. automatically start ansible playbook with correct values to deploy nginx

Terraform will output the public ip address, which you can then connect to e.g.

```
curl http://terraform-output-public_ip
```

This should display the `Welcome to nginx!` webpage.

To teardown everything, run

```
terraform destroy
```

**NOTE**: You can also run the playbook manually on a running instance. Change 
your `ansible.cfg` accordingly or pass via cli. 

```
ansible-playbook -i [123.123.123.123], playbook.yaml
```
