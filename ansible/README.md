# Ansible Roles

This is the root directory for [ansible
roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html).
The [roles](roles) directory holds all the ansible roles (e.g. `setup_docker`,
`init_cockroachdb`..). For further information on the ansible directory structure, see [role directory
structure](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html#role-directory-structure)
for more information on the layout.

## How to use a role

To use a role, add the `roles` keyword to your ``playbook.yml``as shown below. The role name must match the directory name. 
```
- hosts: all
  roles: 
    - setup_docker
```

A full example can be found in [cockroach_playbook.yml](./cockroach_playbook.yml)

## How to create a new role
To create a new role, simply create a new directory `roles/YOUR_ROLE_NAME` and
a `tasks` directory inside that directory. In the `tasks` directory, you create
the file `main.yml`, in which you only list the tasks that the role executes. 
Ansible will also look for six other directories that can be used to add functionality to the role. For further information, refer to the [official documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html#role-directory-structure).

Once created you can then use the role as described above. 
