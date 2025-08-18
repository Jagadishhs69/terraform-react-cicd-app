terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.env}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.env}-igw" }
}

resource "aws_subnet" "public" {
  for_each                = { for i, az in var.azs : i => az }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr, 4, each.key)
  availability_zone       = each.value
  map_public_ip_on_launch = true
  tags = { Name = "${var.env}-public-${each.value}" }
}

resource "aws_subnet" "private" {
  for_each          = { for i, az in var.azs : i => az }
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 4, each.key + 4)
  availability_zone = each.value
  tags = { Name = "${var.env}-private-${each.value}" }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.env}-nat-eip"
  }
}


resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  tags          = { Name = "${var.env}-nat" }
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
  tags = { Name = "${var.env}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route { 
    cidr_block = "0.0.0.0/0" 
    nat_gateway_id = aws_nat_gateway.nat.id 
  }
  tags = { 
    Name = "${var.env}-private-rt" 
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
