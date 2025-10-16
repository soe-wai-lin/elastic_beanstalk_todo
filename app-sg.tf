resource "aws_security_group" "app-sg" {
  name        = "app-sg"
  description = "allow_ALB access"
  vpc_id      = aws_vpc.terra_vpc.id

  tags = {
    Name = "App-Security-Group"
  }
}


# resource "aws_security_group_rule" "allow_alb_sg_app" {
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   source_security_group_id = aws_security_group.alb-sg.id
#   security_group_id = aws_security_group.app-sg.id
# }

resource "aws_security_group_rule" "allow_all_out_sg_app" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app-sg.id
}