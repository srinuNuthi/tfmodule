provider "aws" {
  region = "us-east-1"
}

module "vpc_module" {
  source = "C:/Users/USER/Documents/avinash/Terraform/vpcModule"
}