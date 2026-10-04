terraform {
  backend "s3" {
    bucket  = "caffe-terraform"
    key     = "state/infra.tfstate"
    region  = "eu-central-1"
    encrypt = true

    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.67.0"
    }
  }

  required_version = "1.13.1"
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Project = "caffe"
    }
  }
}
