TF_DIR := terraform          # single IaC directory

.PHONY: lint plan apply destroy ansible

lint:
	tflint --init && tflint
	tfsec $(TF_DIR)
	checkov -d $(TF_DIR) --external-checks-dir security/checkov-policies

plan: lint
	cd $(TF_DIR) && terraform init -upgrade && terraform plan -refresh=false -out=plan.tfplan

apply:
	cd $(TF_DIR) && terraform apply -auto-approve plan.tfplan


destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve