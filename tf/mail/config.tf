terraform {
  backend "s3" {
    bucket  = "caffe-terraform"
    key     = "state/mail.tfstate"
    region  = "eu-central-1"
    encrypt = true

    dynamodb_table = "caffe-terraform"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.60.0"
    }

    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.48.0"
    }
  }

  required_version = "1.8.0"
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Project = "caffe"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
