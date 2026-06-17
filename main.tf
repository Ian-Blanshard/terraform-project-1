provider "aws" {
  region = "eu-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app_server_ianb" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["sg-05985aecc5497ed1a"]


  tags = {
    Name = "ianb_learn-terraform"
  }
}

resource "aws_s3_bucket" "ianb-terraform-bucket" {
	bucket = "ianb-terraform-bucket"
	tags = {
    Name = "ianb-learn-terraform"
  }
}

resource "aws_ecr_repository" "ianb-task-app-repo" {
  name                 = "ianb-task-app-repo"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "ianb"
  }
}

