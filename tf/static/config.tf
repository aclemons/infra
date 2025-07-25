terraform {
  backend "s3" {
    bucket  = "caffe-terraform"
    key     = "state/static.tfstate"
    region  = "eu-central-1"
    encrypt = true

    dynamodb_table = "caffe-terraform"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.4.0"
    }
  }

  required_version = "1.10.3"
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Project = "caffe"
    }
  }
}
