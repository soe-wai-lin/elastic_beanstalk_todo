

resource "aws_secretsmanager_secret" "scrmgr" {
  name        = var.scrmgr_name
  description = "MySQL credentials for Dev Todolist with automatic rotation"
  depends_on  = [aws_db_instance.mysql_rds]
}

data "aws_db_instance" "mysql_rds" {
  db_instance_identifier = "tododb"
  depends_on             = [aws_db_instance.mysql_rds]
}

resource "random_password" "rds_password" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.scrmgr.id
  secret_string = jsonencode({
    username = data.aws_db_instance.mysql_rds.master_username
    # password = random_password.rds_password.result
    password = var.db_password
    engine   = data.aws_db_instance.mysql_rds.engine
    host     = data.aws_db_instance.mysql_rds.address
    port     = data.aws_db_instance.mysql_rds.port
    dbname   = data.aws_db_instance.mysql_rds.db_instance_identifier
  })
}

# IAM Role for rotation Lambda
resource "aws_iam_role" "rotation_role" {
  name               = "todolist-secret-rotation-role"
  assume_role_policy = data.aws_iam_policy_document.rotation_assume.json
}

data "aws_iam_policy_document" "rotation_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "rotation_execution" {
  role       = aws_iam_role.rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "rotation_secrets" {
  role       = aws_iam_role.rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "rotation_rds" {
  role       = aws_iam_role.rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

# Add VPC access permission
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "archive_file" "rotation_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_rotation.zip"
}

# Lambda function for rotation (use AWS-provided template)
resource "aws_lambda_function" "todolist_rotation" {
  function_name = "todolist-latest"
  role          = aws_iam_role.rotation_role.arn
  handler       = "SecretsManagerRDSMySQLRotationSingleUser.lambda_handler"
  runtime       = "python3.9"
  timeout       = 300

  filename         = data.archive_file.rotation_zip.output_path
  source_code_hash = data.archive_file.rotation_zip.output_base64sha256

  vpc_config {
    subnet_ids         = [aws_subnet.terra_vpc_data_01.id, aws_subnet.terra_vpc_data_02.id]
    security_group_ids = [aws_security_group.data-sg.id]
  }
  depends_on = [aws_db_instance.mysql_rds]

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.region}.amazonaws.com"
    }
  }
}

data "aws_region" "current" {}

# Enable automatic rotation
resource "aws_secretsmanager_secret_rotation" "todolist_rotation" {
  secret_id           = aws_secretsmanager_secret.scrmgr.id
  rotation_lambda_arn = aws_lambda_function.todolist_rotation.arn
  rotate_immediately  = false

  rotation_rules {
    automatically_after_days = 7
  }
}

resource "aws_lambda_permission" "allow_secretsmanager" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.todolist_rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
}


 