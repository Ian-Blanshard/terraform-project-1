provider "aws" {
  region = "eu-west-2"
}

resource "aws_elastic_beanstalk_application" "example_app" {
  name        = "ianb-task-listing-app"
  description = "Task listing app"
}

resource "aws_elastic_beanstalk_environment" "example_app_environment" {
  name                = "ianb-task-listing-app-environment-v7"
  application         = aws_elastic_beanstalk_application.example_app.name
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

resource "aws_iam_instance_profile" "example_app_ec2_instance_profile" {
  name = "ianb-task-listing-app-ec2-instance-profile"
  role = aws_iam_role.example_app_ec2_role.name
}

resource "aws_iam_role" "example_app_ec2_role" {
  name = "ianb-task-listing-app-ec2-instance-role"

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
