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
  region  = var.aws_region
  profile = var.aws_profile
}

// This data object hold the available availability zones in defined region
data "aws_availability_zones" "available" {
  state = "available"
}

//Step1: VPC
resource "aws_vpc" "tutorial_vpc" {

  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "tutorial_vpc∂"
  }
}

//Step2: Internet Gateway
resource "aws_internet_gateway" "tutorial_igw" {
  vpc_id = aws_vpc.tutorial_vpc.id

  tags = {
    "Name" = "tutorial_igw"
  }
}

//Step3: Subnets

//Public Subnet
resource "aws_subnet" "tutorial_pub_subnet" {
  count             = var.subnet_count.public
  vpc_id            = aws_vpc.tutorial_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    "Name" = "tutorial_public_subnet_${count.index}"
  }
}

//Private Subnet
resource "aws_subnet" "tutorial_pri_subnet" {
  count             = var.subnet_count.private
  vpc_id            = aws_vpc.tutorial_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    "Name" = "tutorial_private_subnet_${count.index}"
  }
}

//Step4: Route Tables

//Public Subnet Route Tables
resource "aws_route_table" "tutorial_pub_rt" {
  vpc_id = aws_vpc.tutorial_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tutorial_igw.id
  }
}

//Public Subnet Route Table Associations
resource "aws_route_table_association" "public" {
  count          = var.subnet_count.public
  route_table_id = aws_route_table.tutorial_pub_rt.id
  subnet_id      = aws_subnet.tutorial_pub_subnet[count.index].id
}

//Private Subnet Route Tables
resource "aws_route_table" "tutorial_pri_rt" {
  vpc_id = aws_vpc.tutorial_vpc.id
}

//Private Subnet Route Table Associations
resource "aws_route_table_association" "private" {
  count          = var.subnet_count.private
  route_table_id = aws_route_table.tutorial_pri_rt.id
  subnet_id      = aws_subnet.tutorial_pri_subnet[count.index].id
}
