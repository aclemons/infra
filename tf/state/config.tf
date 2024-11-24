terraform {
  backend "s3" {
    bucket  = "caffe-terraform"
    key     = "state/infra.tfstate"
    region  = "eu-central-1"
    encrypt = true

    dynamodb_table = "caffe-terraform"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.77.0"
    }
  }

  required_version = "1.8.6"
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Project = "caffe"
    }
  }
}
