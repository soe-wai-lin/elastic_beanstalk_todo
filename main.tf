resource "aws_vpc" "terra_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  tags = {
    Name = var.vpc_name
  }

}

resource "aws_subnet" "terra_vpc_pub_01" {
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = var.pub_sub_01
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-subnet01"
  }
}

resource "aws_subnet" "terra_vpc_pub_02" {
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = var.pub_sub_02
  availability_zone       = "ap-southeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-subnet02"
  }
}

resource "aws_subnet" "terra_vpc_priv_01" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = var.priv_sub_01
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "app-subnet01"
  }
}

resource "aws_subnet" "terra_vpc_priv_02" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = var.priv_sub_02
  availability_zone = "ap-southeast-2b"

  tags = {
    Name = "app-subnet02"
  }
}

resource "aws_subnet" "terra_vpc_data_01" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = var.data_sub_01
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "data-subnet01"
  }
}

resource "aws_subnet" "terra_vpc_data_02" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = var.data_sub_02
  availability_zone = "ap-southeast-2b"

  tags = {
    Name = "data-subnet02"
  }
}

resource "aws_internet_gateway" "terra_igw" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "todolist-igw"
  }
}

resource "aws_route_table" "terra_pub_rt" {
  vpc_id = aws_vpc.terra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra_igw.id
  }

  tags = {
    Name = "todolist-publicrt"
  }
}

# resource "aws_route_table" "main_rt" {
#   vpc_id = aws_vpc.terra_vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.terra_natgw.id
#   }

#   tags = {
#     Name = "main_rt"
#   }
# }

resource "aws_route_table_association" "terr_pub_asso_a" {
  subnet_id      = aws_subnet.terra_vpc_pub_01.id
  route_table_id = aws_route_table.terra_pub_rt.id
}

resource "aws_route_table_association" "terr_pub_asso_b" {
  subnet_id      = aws_subnet.terra_vpc_pub_02.id
  route_table_id = aws_route_table.terra_pub_rt.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}


resource "aws_nat_gateway" "terra_natgw" {
  subnet_id     = aws_subnet.terra_vpc_pub_01.id
  allocation_id = aws_eip.nat_eip.id

  tags = {
    Name = "terra-nat-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.terra_igw]
}

resource "aws_route_table" "terra_pri_rt" {
  vpc_id = aws_vpc.terra_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terra_natgw.id
  }

  tags = {
    Name = "terra_pri_rt"
  }
}

resource "aws_route_table_association" "terr_pri_asso_a" {
  subnet_id      = aws_subnet.terra_vpc_priv_01.id
  route_table_id = aws_route_table.terra_pri_rt.id
}

resource "aws_route_table_association" "terr_pri_asso_b" {
  subnet_id      = aws_subnet.terra_vpc_priv_02.id
  route_table_id = aws_route_table.terra_pri_rt.id
}

resource "aws_route_table_association" "terr_data_asso_a" {
  subnet_id      = aws_subnet.terra_vpc_data_01.id
  route_table_id = aws_route_table.terra_pri_rt.id
}

resource "aws_route_table_association" "terr_data_asso_b" {
  subnet_id      = aws_subnet.terra_vpc_data_02.id
  route_table_id = aws_route_table.terra_pri_rt.id
}


# data "terraform_remote_state" "db" {
#   backend = "s3"

#   config = {
#     bucket = "swlbacket-state-store"
#     key = "vpc/terraform.tfstate"
#     region = "ap-southeast-1"
#     use_lockfile = "true"
#   }
# }

