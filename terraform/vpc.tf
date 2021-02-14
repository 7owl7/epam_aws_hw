#----------------------------------------------------------
# EPAM aws homework vpc.tf file
#----------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "${var.project_name}-${var.env}-vpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.region}a"
  cidr_block        = var.subnet1_cidr
  tags = {
    Name = "${var.project_name}-${var.env}-subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.region}b"
  cidr_block        = var.subnet2_cidr
  tags = {
    Name = "${var.project_name}-${var.env}-subnet2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.env}-vpc-IGW"
  }
}

resource "aws_default_route_table" "default_rt" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.project_name}-${var.env}-vpc-default-route-table"
  }
}

resource "aws_security_group" "wpress" {
  name   = "${var.project_name}-${var.env}-wpress-SG"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.subnet1_cidr, var.subnet2_cidr]
    description = "HTTP access"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-${var.env}-wpress-SG"
  }
}

resource "aws_security_group" "db" {
  name   = "${var.project_name}-${var.env}-db-SG"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.subnet1_cidr, var.subnet2_cidr]
    description = "MYSQL access"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-${var.env}-db-SG"
  }
}

resource "aws_security_group" "nfs" {
  name   = "${var.project_name}-${var.env}-nfs-SG"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.subnet1_cidr, var.subnet2_cidr]
    description = "NFS access"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-${var.env}-nfs-SG"
  }
}

resource "aws_security_group" "alb" {
  name   = "${var.project_name}-${var.env}-alb-SG"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-${var.env}-alb-SG"
  }
}
