from proxmoxer import ProxmoxAPI
from argparse import ArgumentParser

parser = ArgumentParser(description='Delete protected VMs from all Proxmox nodes on one server.')
parser.add_argument('-H', '--host', required=True, help='Address of the Proxmox host')
parser.add_argument('-u', '--username', required=True, help='Proxmox PAM user, i.e. "root@pam"')
parser.add_argument('-p', '--password', required=True)
args = parser.parse_args()

proxmox = ProxmoxAPI(args.host, user=args.username, password=args.password, verify_ssl=False)

def should_delete_vm(vm: dict):
	return vm['name'].startswith('ri-proxmox-vm')

worklist = []
for node in proxmox.nodes.get():
	for vm in proxmox.nodes(node['node']).qemu.get():
		if should_delete_vm(vm):
			worklist.append((vm, proxmox.nodes(node['node']).qemu(vm['vmid'])))

# First, remove protection and stop the VM. Stopping is asynchronous, so the program continues before the VM is actually stopped.
for _, vm_api in worklist:
	vm_api.config.set(protection=0)
	vm_api.status.stop.post()

# Then, delete the VMs without checking if they are stopped. Usually, iterating over all VMs gives Proxmox enough time to stop the VM.
for vm_data, vm_api in worklist:
	vm_api.delete()
	print('✔ ' + vm_data['name'])
	
