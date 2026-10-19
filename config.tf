terraform {
  backend "s3" {
    bucket              = "globomatics-tofu-state-222234418877-us-east-2"
    key                 = "globomatics/lab/terraform.tfstate"
    region              = "us-east-2"
    encrypt             = true
    use_lockfile        = true
    allowed_account_ids = ["222234418877"]
  }

  required_version = ">= 1.11.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  allowed_account_ids = ["222234418877"]
  region              = "us-east-2"
  default_tags {
    tags = {
      Project   = "globomatics"
      ManagedBy = "OpenTofu"
    }
  }
}

variable "ssh_source_cidr" {
  description = "Una única IPv4 pública autorizada para SSH."
  type        = string
  default     = "181.114.108.136/32"
  validation {
    condition     = can(cidrnetmask(var.ssh_source_cidr)) && endswith(var.ssh_source_cidr, "/32")
    error_message = "SSH requiere una dirección IPv4 con máscara /32."
  }
}

variable "ssh_public_key_path" {
  description = "Ruta local de la clave PÚBLICA. La privada no entra en OpenTofu ni en el estado."
  type        = string
  default     = "~/globomatics-ec2.pub"
}

locals {
  project = "globomatics"
  suffix  = "${local.project}-lab"
}

resource "aws_resourcegroups_group" "globomatics" {
  name        = "rg-${local.suffix}"
  description = "Red y servidores de la aplicacion globomatics"
  resource_query {
    type = "TAG_FILTERS_1_0"
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters          = [{ Key = "Project", Values = [local.project] }]
    })
  }
  tags = { Name = "rg-${local.suffix}" }
}
