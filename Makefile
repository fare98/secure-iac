ENV ?= lab
TF_DIR := terraform/envs/$(ENV)

.PHONY: lint plan apply destroy ansible

lint:        ## run all linters
	tflint --init && tflint
	tfsec $(TF_DIR)
	checkov -d $(TF_DIR)
	ansible-lint ansible

plan: lint   ## terraform plan
	cd $(TF_DIR) && terraform init -upgrade && terraform plan -out=plan.tfplan

apply:       ## terraform apply + ansible
	cd $(TF_DIR) && terraform apply -auto-approve plan.tfplan
	ansible-playbook -i ansible/inventories/$(ENV)/hosts.yaml ansible/site.yml

destroy:     ## remove all lab resources
	cd $(TF_DIR) && terraform destroy -auto-approve

ansible:     ## run only ansible hardening
	ansible-playbook -i ansible/inventories/$(ENV)/hosts.yaml ansible/site.yml
