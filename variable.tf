variable "aws_profile" {
  type        = string
  default     = "prod"
  description = "Check this profile name in ~/.aws/config"
}

variable "aws_region" {
  default = "ap-southeast-2"
  type    = string
}

variable "vpc_name" {
  default = "todolist-EB-vpc"
}

variable "vpc_cidr_block" {
  default = "10.5.0.0/16"
  type    = string
}

variable "pub_sub_01" {
  default = "10.5.1.0/24"
  type    = string
}

variable "pub_sub_02" {
  default = "10.5.2.0/24"
  type    = string
}

variable "priv_sub_01" {
  default = "10.5.10.0/24"
  type    = string
}

variable "priv_sub_02" {
  default = "10.5.11.0/24"
  type    = string
}

variable "data_sub_01" {
  default = "10.5.20.0/24"
  type    = string
}

variable "data_sub_02" {
  default = "10.5.21.0/24"
  type    = string
}

variable "asg_min" {
  default = 1
  type    = number
}

variable "asg_max" {
  default = 2
  type    = number
}

variable "asg_desired_capacity" {
  default = 2
  type    = number
}

variable "scrmgr_name" {
  default     = "scr4"
  description = "Secret Manger name"
}


# variable "env_vars" {
#   type        = map(string)
#   description = "Application environment variables for EB"
#   default = {
#     SECRET_NAME = aws_secretsmanager_secret.scrmgr.name
#     DB_ENDPOINT = aws_db_instance.mysql_rds.address
#     DB_NAME     = aws_db_instance.mysql_rds.db_name
#     # Add DB_HOST, DB_NAME, etc., or use your Secrets Manager integration in app code
#   }
# }
