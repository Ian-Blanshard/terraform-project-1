provider "aws" {
  region = "eu-west-2"
}

# 1. ECR Repository
resource "aws_ecr_repository" "ianb_task_app_repo" {
  name                 = "ianb-task-app-repo"
  image_tag_mutability = "MUTABLE"
  tags = {
    Name = "ianb"
  }
}

# 2. Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "example_app" {
  name        = "ianb-task-listing-app"
  description = "Task listing app"
}

# 3. Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "example_app_environment" {
  name                = "ianb-task-listing-app-environment-v10" # Bumped version to bypass cached failures
  application         = aws_elastic_beanstalk_application.example_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.13.2 running Docker"

  # FIX: Attach the Service Role required by Amazon Linux 2023 to pull baseline assets from S3
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.beanstalk_service_role.name
  }

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

# 4. IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "example_app_ec2_instance_profile" {
  name = "ianb-task-listing-app-ec2-instance-profile"
  role = aws_iam_role.example_app_ec2_role.name
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

# 5. EC2 Instance Profile Policy Attachments
resource "aws_iam_role_policy_attachment" "attach_web" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "attach_worker" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "example_app_ec2_role_policy_attachment" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 6. REQUIRED BEANSTALK SERVICE ROLE (Resolves S3 Access Denied)
data "aws_iam_policy_document" "beanstalk_service_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "beanstalk_service_role" {
  name               = "ianb-beanstalk-service-role"
  assume_role_policy = data.aws_iam_policy_document.beanstalk_service_assume_role.json
}

resource "aws_iam_role_policy_attachment" "beanstalk_service_enhanced" {
  role       = aws_iam_role.beanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}

resource "aws_iam_role_policy_attachment" "beanstalk_service_enhanced_health" {
  role       = aws_iam_role.beanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}
