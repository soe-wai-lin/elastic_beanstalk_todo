resource "aws_security_group" "data-sg" {
  name        = "data-sg"
  description = "access_app_to_data"
  vpc_id      = aws_vpc.terra_vpc.id

  tags = {
    Name = "Data-Security-Group"
  }
}
resource "aws_security_group_rule" "app_allow_mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app-sg.id
  security_group_id        = aws_security_group.data-sg.id
}

resource "aws_security_group_rule" "mysql_allow_mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.data-sg.id
  security_group_id        = aws_security_group.data-sg.id
}

