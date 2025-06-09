all:
  hosts:
%{ for vm_name, vm_config in vms ~}
    ${vm_name}:
      ansible_host: ${vm_config.ansible_host}
      ansible_user: ${vm_config.ansible_user}
%{ endfor ~}
  children:
    idp_vms:
      hosts:
%{ for vm_name, vm_config in vms ~}
        ${vm_name}:
%{ endfor ~}
  vars:
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'