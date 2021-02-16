# Demo 

This is the demonstration for our final presentation as described in [story
294](https://app.clubhouse.io/thinkdeep/story/294/create-a-scenario-story-for-the-final-demonstration-that-includes-the-use-of-the-database-in-an-easy-and-understandable-way)

There are two python scripts, `counter.py` and `listener.py`.  Install requirements with pip e.g.
`pip install -U -r requirements.txt`. Change the sql connection string in `env.sh` 
for both connections according to the nodes you want to use and source it.

You can then run the counter script as well as the listener (e.g. in new terminal).

TODO: no network partition between both 

## Build infra

Inside the `terraform` directory, run
```
terraform apply -target=module.gcp -target=module.hetzner
```

SSH into the deployer machine on hetzner. 

```
cd /resinfra/
git pull
git checkout demonstration
cd ansible
```

Change or add to `cockroach_hosts.ini`
```
ansible_ssh_private_key_file=/root/.ssh/ri_key2 ansible_ssh_user=resinfra
```

Run ansible playbook with
```
ansible-playbook cockroach_playbook.yml -i cockroach_hosts.ini -u root --ssh-common-args='-o StrictHostKeyChecking=no' --private-key ~/.ssh/ri_key --extra-vars 'priv_ip_list=10.2.0.2,10.2.0.3,10.3.0.1,10.3.0.2  ansible_python_interpreter=/usr/bin/python3'   
```

If your key is not there or you have different keys for different providers, copy it
```
scp -i ~/.ssh/ri_key /home/tim/.ssh/ri_key root@157.90.123.202:/root/.ssh/ri_key2
```


Private IP addresses
* GCP: 10.2.0.2, 10.2.0.3
* Hetzner: 10.3.0.1, 10.3.0.2
