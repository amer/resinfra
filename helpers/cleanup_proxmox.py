from proxmoxer import ProxmoxAPI
from argparse import ArgumentParser

parser = ArgumentParser(description='Delete protected VMs from all Proxmox nodes on one server.')
parser.add_argument('-p', '--password', help='proxmox root password', required=True)
args = parser.parse_args()

proxmox = ProxmoxAPI('92.204.175.162', user='root@pam', password=args.password, verify_ssl=False)

def should_delete_vm(vm: dict):
	return vm['name'].startswith('ri-proxmox-vm')

worklist = []
for node in proxmox.nodes.get():
	for vm in proxmox.nodes(node['node']).qemu.get():
		if should_delete_vm(vm):
			worklist.append((vm, proxmox.nodes(node['node']).qemu(vm['vmid'])))
			
for _, vm_api in worklist:
	vm_api.config.set(protection=0)
	vm_api.status.stop.post()
			
for vm_data, vm_api in worklist:
	vm_api.delete()
	print('✔ ' + vm_data['name'])
	