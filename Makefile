TF_MODULE_PATH=./terraform/modules/base_infra
AWS_CREDENTIALS=$(HOME)/.aws

DOCKER_RUN=docker run --rm -it \
  -v $(PWD):/workspace \
  -v $(AWS_CREDENTIALS):/root/.aws:ro \
  -w /workspace/$(TF_MODULE_PATH) hashicorp/terraform:latest

tf-init:  ## Initialize Terraform
	$(DOCKER_RUN) init

tf-plan: ## Plan Terraform changes
	$(DOCKER_RUN) plan -var-file=/workspace/terraform/configs/terraform.tfvars

tf-apply: ## Apply Terraform changes
	$(DOCKER_RUN) apply -auto-approve -var-file=/workspace/terraform/configs/terraform.tfvars

tf-destroy: ## Destroy Terraform resources
	$(DOCKER_RUN) destroy -auto-approve -var-file=/workspace/terraform/configs/terraform.tfvars
