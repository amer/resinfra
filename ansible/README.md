# Ansible Roles

This is our root directory for [ansible
roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html).
Each role has a directory with the same name (e.g. `setup_docker`,
`init_cockroachdb`..) and subdirectories, depending on the needs for a specific
role. You can check the [role directory
structure](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html#role-directory-structure)
for more information on the layout.

## How to use a role

To use a role, you simply use the roles keyword as shown below. The role name must match the directory name. 
```
- hosts: all
  roles: 
    - setup_docker
```

A full example can be found in [cockroach_playbook.yml](./cockroach_playbook.yml)

## How to create a new role
To create a new role, simply create a new directory `roles/YOUR_ROLE_NAME` and
a `tasks` directory inside that directory. In the `tasks` directory you create
the file `main.yml`, in which you simply list tasks as usual, but without
specifying the `hosts` keyword. Once created you can then use the role as
described above. 

