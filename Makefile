TF_DIR := terraform          # single IaC directory

.PHONY: lint plan apply destroy ansible

lint:
	tflint --init && tflint
	tfsec $(TF_DIR)
	checkov -d $(TF_DIR)

plan: lint
	cd $(TF_DIR) && terraform init -upgrade && terraform plan -refresh=false -out=plan.tfplan

apply:
	cd $(TF_DIR) && terraform apply -auto-approve plan.tfplan || (terraform taint module.vm.proxmox_vm_qemu.this[0] 2>/dev/null; terraform apply -auto-approve)


destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve