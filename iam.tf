resource "aws_iam_role" "Todo-EB-SM-IAM-Role" {
  name = "Todo-EB-SM-IAM-Role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ec2"
  }
}

# Attach the AWS managed policy AmazonSSMManagedInstanceCore
resource "aws_iam_role_policy_attachment" "eb_webtier" {
  role       = aws_iam_role.Todo-EB-SM-IAM-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}


resource "aws_iam_role_policy_attachment" "eb_docker" {
  role       = aws_iam_role.Todo-EB-SM-IAM-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "eb_workertier" {
  role       = aws_iam_role.Todo-EB-SM-IAM-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "secret_access" {
  role       = aws_iam_role.Todo-EB-SM-IAM-Role.name
  policy_arn = "arn:aws:iam::851725184910:policy/Todo-EB-Secret-IAM-Policy"
  depends_on = [aws_iam_policy.secret_mgr]
}

# Attach the AWS managed policy AmazonSSMManagedInstanceCore
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.Todo-EB-SM-IAM-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "Todo-EB-SM-IAM-Role"
  role = aws_iam_role.Todo-EB-SM-IAM-Role.name
}


#################################
### Creating Secret Access policy ###
#################################

data "aws_secretsmanager_secret" "scrmgr" {
  name       = var.scrmgr_name
  depends_on = [aws_secretsmanager_secret.scrmgr]
}

# IAM policy for the bucket
resource "aws_iam_policy" "secret_mgr" {
  name        = "Todo-EB-Secret-IAM-Policy"
  description = "Todo-EB-Secret-IAM-Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",

        ]
        Resource = "${data.aws_secretsmanager_secret.scrmgr.arn}"
      }
    ]
  })
}


##### Create Service Role #####

resource "aws_iam_role" "aws-elasticbeanstalk-service-role" {
  name        = "aws-elasticbeanstalk-service-role"
  description = "Allows access to other AWS service resources that are required to create and manage environments."

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkEnhancedHealth" {
  role       = aws_iam_role.aws-elasticbeanstalk-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy" {
  role       = aws_iam_role.aws-elasticbeanstalk-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}
