terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"

backend "s3" {
    bucket = "ianb-terraform-state-bucket"
    key    = "ianb/state"
    region = "eu-west-2"
  }
}

