# Terraform for AWS

This Terraform script deploys a basic EC2 vm to AWS. The vm runs the latest Ubuntu version and has nginx installed for demonstration purposes.

## Setup

First of all, you need to retrieve the credentials of your AWS account. After that you need to copy and paste the credentials in ~/.aws/credentials. Like this:

```
[default]
aws_access_key_id=123
aws_secret_access_key=123
aws_session_token=123
```


## Running the deployment

Open the directory where the file `main.tf` is located.

After that initialize Terraform with the following command.

``` 
terraform init 
```

You can plan you deployment with:

```
terraform plan
```

Finally, you can deploy it:

```
terraform apply
```

After the script has finished it will show you the public IP address of the deployed vm in the command line. You can connect to the vm with:

```
ssh root@host -i YOUR_KEY_FILE

e.g.:
ssh root@192.168.2.201 -i ~/.ssh/id_rsa
```

## Teardown
You can stop the deployed services by issuing the following command:

```
terraform destroy
```
