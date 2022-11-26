terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-2"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "vpc-0abcadd97935d6d26"

  tags = {
    Name = "vpc_igw-for-rds"
  }
}

resource "aws_default_subnet" "public_subnet" {
  count              = 2
  map_public_ip_on_launch = true
  availability_zone = element(["us-east-2a", "us-east-2b"] , count.index)

  tags = {
    Name = "public-subnet-for-rds"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = "vpc-0abcadd97935d6d26"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt-for-rds"
  }
}

resource "aws_route_table_association" "public_rt_asso" {
  count = 2
  subnet_id   = element(aws_default_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "cc-rds" {
  vpc_id      = "vpc-0abcadd97935d6d26"
  name        = "cc-rds"
  description = "Allow all inbound for MS SQL Server"
  
  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "cc-rds-mssql" {
  identifier             = "database-sql-ms"
  instance_class         = "db.t3.small"
  allocated_storage      = 20
  engine = "sqlserver-ex"
  engine_version = "15.00.4236.7.v1"
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.cc-rds.id]
  username               = "testCC"
  password               = "Abcd1234"
}
