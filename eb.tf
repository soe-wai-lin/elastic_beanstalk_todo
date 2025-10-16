resource "aws_elastic_beanstalk_application" "todo" {
  name        = "Todo-List-EB-App"
  description = "Todo-List-EB-App"

  appversion_lifecycle {
    service_role          = aws_iam_role.aws-elasticbeanstalk-service-role.arn
  }
}

# # resource "aws_s3_bucket" "default" {
# #   bucket = "tftest"
# # }

# # resource "aws_s3_object" "default" {
# #   bucket = aws_s3_bucket.default.id
# #   key    = "beanstalk/eb-rds-todo-app-code-v3.zip"
# #   source = "${path.module}/eb-rds-todo-app-code-v3.zip"
# # }

resource "aws_elastic_beanstalk_application_version" "default" {
  name        = "Todo-List-EB-App-label"
  application = aws_elastic_beanstalk_application.todo.name
  description = "application version created by terraform"
  bucket      = "eb-todolist-test"
  key         = "eb-rds-todo-app-code-v3.zip"
}

resource "aws_elastic_beanstalk_environment" "example" {
  name                = "Todo-List-EB-App-env"
  application         = aws_elastic_beanstalk_application.todo.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.php_al2023.name 


# Use this application version
  version_label       = aws_elastic_beanstalk_application_version.default.name
  tier                = "WebServer"

  # ---- Load balancer: ALB ----
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

# Attach ALB security groups (use elbv2 namespace, not classic ELB)
  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = aws_security_group.alb-sg.id
  }

  # ALB scheme: internet facing or internal
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internet facing"
  }

  # ---- VPC/Subnets wiring ----
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.terra_vpc.id
  }
  # Instance subnets
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    # value     = join(",", var.instance_subnet_ids)
    value = join(",", [
        aws_subnet.terra_vpc_priv_01.id,
        aws_subnet.terra_vpc_priv_02.id
    ])

  }

# Load balancer subnets
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", [
        aws_subnet.terra_vpc_pub_01.id,
        aws_subnet.terra_vpc_pub_02.id
    ])

  }

  # ---- EC2/Launch configuration ----
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "Todo-EB-SM-IAM-Role"
  }

# Attach instance security groups
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.app-sg.id
  }

  # ---- Auto Scaling capacity ----
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = var.asg_min
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.asg_max
  }

  # ---- Health & Deployments ----
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "basic"
  }

#   setting {
#     namespace = "aws:elasticbeanstalk:command"
#     name      = "DeploymentPolicy"
#     value     = "Rolling"
#   }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/health.html"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = "200"
  }

  # ---- Explicitly keep nginx proxy (default on AL2/AL2023) ----
  setting {
    namespace = "aws:elasticbeanstalk:environment:proxy"
    name      = "ProxyServer"
    value     = "nginx"
  }

  # ---- Application environment variables ----
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "SECRET_NAME"
    value = aws_secretsmanager_secret.scrmgr.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "DB_ENDPOINT"
    value = aws_db_instance.mysql_rds.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "DB_NAME"
    value = aws_db_instance.mysql_rds.db_name
  }

# # ---- Application environment variables ----
#   dynamic "setting" {
#     for_each = var.env_vars
#     content {
#       namespace = "aws:elasticbeanstalk:application:environment"
#       name      = setting.key
#       value     = setting.value
#     }
#   }

#   tags = var.tags

}


data "aws_elastic_beanstalk_solution_stack" "php_al2023" {
  most_recent = true
  # Example: "64bit Amazon Linux 2023 v4.x.x running PHP 8.2"
  name_regex  = "^64bit Amazon Linux 2023 .* running PHP 8.3$"
}
