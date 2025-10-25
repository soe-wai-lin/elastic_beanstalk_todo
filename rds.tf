resource "aws_db_subnet_group" "my_db_subnet_group" {
  name = "todo_rds_subnet_group"
  subnet_ids = [
    aws_subnet.terra_vpc_data_01.id, # Replace with your subnet IDs
    aws_subnet.terra_vpc_data_02.id
  ]
  depends_on = [aws_vpc.terra_vpc]
}

# resource "aws_kms_key" "kms" {
#   description = "Example KMS Key"
# }

resource "aws_db_instance" "mysql_rds" {
  identifier           = var.db_identifier
  db_name              = var.db_name
  engine               = var.engine
  engine_version       = "8.0.42"
  allocated_storage    = 20
  instance_class       = var.db_instance_class
  username             = var.db_username
  password             = var.db_password # Using a variable is a better practice
  skip_final_snapshot  = true
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [
    aws_security_group.data-sg.id
  ]
  depends_on = [aws_db_subnet_group.my_db_subnet_group]
}