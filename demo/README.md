# Demo 

This is the demonstration for our final presentation as described in [story
294](https://app.clubhouse.io/thinkdeep/story/294/create-a-scenario-story-for-the-final-demonstration-that-includes-the-use-of-the-database-in-an-easy-and-understandable-way)


## Build infra

Inside the `terraform` directory, run
```
terraform apply -target=module.gcp -target=module.hetzner
```

SSH into the deployer machine on hetzner. 

```
cd /resinfra/
git reset --hard
git pull
git checkout demonstration
cd ansible
```

Change or add to `cockroach_hosts.ini`, example can found in `demonstration` dir.
```
ansible_ssh_private_key_file=/root/.ssh/ri_key2 ansible_ssh_user=resinfra
```

Run ansible playbook in ansible dir with
```
ansible-playbook cockroach_playbook.yml -i ../demo/cockroach_hosts.ini -u root --ssh-common-args='-o StrictHostKeyChecking=no' --private-key ~/.ssh/ri_key --extra-vars 'priv_ip_list=10.2.0.2,10.2.0.3,10.3.0.2,10.3.0.3,10.3.0.4 ansible_python_interpreter=/usr/bin/python3'   
```

If your key is not there or you have different keys for different providers, copy it
```
scp -i ~/.ssh/ri_key /home/tim/.ssh/ri_key root@157.90.123.202:/root/.ssh/ri_key
```

You can now access cockroach db and dashboard via public ip and port (8080 dashboard, 26257 db).

To reach consul, use port forwarding and connect locally
```
ssh root@159.69.84.187 -i ~/.ssh/ri_key -L 8500:localhost:8500
```

## Run demo

There are two python scripts, `counter.py` and `listener.py`. Install requirements with pip e.g.
`pip install -U -r requirements.txt`. 

Run the counter script by passing the provider name and the ip address of a cockroachdb node

```
python counter.py hetzner 157.90.123.220
python counter.py gcp 104.155.51.108
```

Pass the ip of the hetzner and gcp node to the listener script
```
python listener.py 157.90.123.220 104.155.51.108
```

You can now manually simulate provider outage by stopping the machines on GCP. 
Both scripts will realize that the connection has been lost. Once self-healing
kicks in (or you start the machines in gcp) they will continue to run. 


Private IP addresses
* GCP: 10.2.0.2, 10.2.0.3
* Hetzner: 10.3.0.2, 10.3.0.3, 10.3.0.4
