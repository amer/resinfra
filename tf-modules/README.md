# Terraform modules

This is a suggestion for structuring our terraform scripts into modules to make
it more readable and reusable.  I currently created two modules, one for
`aws-ec2` and one for `hcloud-server` which you can see in the modules
directory. 

Both `aws-ec2` and `hcloud-server` are working and can create multiple
machines! Also, both will correctly output the ips. Feel free to add additional
modules. 

