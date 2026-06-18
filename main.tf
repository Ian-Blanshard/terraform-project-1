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

resource "aws_elastic_beanstalk_application" "example_app" {
  name        = "ianb-task-listing-app"
  description = "Task listing app"
}

resource "aws_elastic_beanstalk_environment" "example_app_environment" {
  name                = "ianb-task-listing-app-environment-v6"
  application         = aws_elastic_beanstalk_application.example_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.13.2 running Docker"
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.example_app_ec2_instance_profile.name
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "EC2KeyName"
    value = "ianb-terraform-ec2"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.beanstalk_service_role.name
  }
}

resource "aws_iam_instance_profile" "example_app_ec2_instance_profile" {
  name = "ianb-task-listing-app-ec2-instance-profile"
  role = aws_iam_role.example_app_ec2_role.name
}

resource "aws_iam_role" "example_app_ec2_role" {
  name = "ianb-task-listing-app-ec2-instance-role"

  // Allows the EC2 instances in our EB environment to assume (take on) this 
  // role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole"
            Principal = {
              Service = "ec2.amazonaws.com"
            }
            Effect = "Allow"
            Sid = ""
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "web_tier_attach" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "multicontainer_docker_attach" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "worker_tier_attach" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role" "beanstalk_service_role" {
  name = "aws-elasticbeanstalk-service-role-ianb"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "elasticbeanstalk.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "beanstalk_s3_assets_policy" {
  name = "allow-beanstalk-platform-assets"
  role = aws_iam_role.beanstalk_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation"]
      Resource = [
        "arn:aws:s3:::elasticbeanstalk-platform-assets-eu-west-2",
        "arn:aws:s3:::elasticbeanstalk-platform-assets-eu-west-2/*"
      ]
    }]
  })
}


resource "aws_iam_role_policy_attachment" "beanstalk_enhanced_health" {
  role       = aws_iam_role.beanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "beanstalk_managed_service" {
  role       = aws_iam_role.beanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}

resource "aws_iam_service_linked_role" "beanstalk_service_linked" {
  aws_service_name = "elasticbeanstalk.amazonaws.com"
}