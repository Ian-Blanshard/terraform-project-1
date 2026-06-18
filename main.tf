provider "aws" {
  region = "eu-west-2"
}

resource "aws_ecr_repository" "ianb_task_app_repo" {
  name                 = "ianb-task-app-repo"

  tags = {
    onwer = "ianb"
  }
}

resource "aws_elastic_beanstalk_application" "example_app" {
  name        = "ianb-task-listing-app"
  description = "Task listing app"
  tags = {
    onwer = "ianb"
  }
}

resource "aws_elastic_beanstalk_environment" "example_app_environment" {
  name        = "ianb-task-listing-app-environment"
  application = aws_elastic_beanstalk_application.example_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.13.2 running Docker"
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.example_app_ec2_instance_profile.name
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "ianb-terraform-ec2"
  }
}

resource "aws_s3_bucket" "docker_files" {
  bucket = "ianb-task-app-docker-files"
  tags = {
    owner = "ianb"
  }
}

resource "aws_db_instance" "rds_app" {
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "18"
  instance_class       = "db.t3.micro"
  identifier           = "ianb-example-app-prod"
  username             = "root"
  password             = "password"
  skip_final_snapshot  = true
  publicly_accessible = true
}

resource "aws_iam_instance_profile" "example_app_ec2_instance_profile" {
  name = "ianb-task-listing-app-ec2-instance-profile"
  role = aws_iam_role.example_app_ec2_role.name
  tags = {
    onwer = "ianb"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example_app_ec2_role" {
  name               = "ianb-task-listing-app-ec2-instance-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}



resource "aws_iam_role_policy_attachment" "attach_web" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}
resource "aws_iam_role_policy_attachment" "attach_docker" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}
resource "aws_iam_role_policy_attachment" "attach_worker" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}
resource "aws_iam_role_policy_attachment" "example_app_ec2_role_policy_attachment" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
