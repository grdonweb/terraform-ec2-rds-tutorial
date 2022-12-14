terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.2"
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
    Name = "tutorial_vpc"
  }
}

//Step2: Internet Gateway
resource "aws_internet_gateway" "tutorial_igw" {
  vpc_id = aws_vpc.tutorial_vpc.id

  tags = {
    "Name" = "tutorial_igw"
  }
}

# //Step3: Subnets

# //Public Subnet
resource "aws_subnet" "tutorial_pub_subnet" {
  count             = var.subnet_count.public
  vpc_id            = aws_vpc.tutorial_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    "Name" = "tutorial_public_subnet_${count.index}"
  }
}

# //Private Subnet
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

//Step5.1: EC2 Security Groups

resource "aws_security_group" "tutorial_web_sg" {

  name        = "tutorial_web_sg"
  description = "Security group for tutorial web servers"
  vpc_id      = aws_vpc.tutorial_vpc.id

  ingress {
    description = "Allow all traffic through HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow SSH connections"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tutorial_web_sg"
  }
}

//Step5.2: RDS Security Groups

resource "aws_security_group" "tutorial_db_sg" {

  name        = "tutorial_db_sg"
  description = "Security group for tutorial databases"
  vpc_id      = aws_vpc.tutorial_vpc.id

  ingress {
    description     = "Allow Mysql traffic from only the web sg"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.tutorial_web_sg.id]
  }
  tags = {
    Name = "tutorial_db_sg"
  }
}

//Step6: Creating db subnet group

resource "aws_db_subnet_group" "tutorial_db_subnet_group" {
  name        = "tutorial_db_subnet_group"
  description = "DB subnet group for tutorial"

  subnet_ids = [for subnet in aws_subnet.tutorial_pri_subnet : subnet.id]
}

// Step 7: Mysql RDS 

resource "aws_db_instance" "tutorial_db" {
  allocated_storage      = var.settings.database.allocated_storage
  engine                 = var.settings.database.engine
  engine_version         = var.settings.database.engine_version
  instance_class         = var.settings.database.instance_class
  db_name                = var.settings.database.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.tutorial_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.tutorial_db_sg.id]
  skip_final_snapshot    = var.settings.database.skip_final_snapshot
}

// Step 8: Creating EC2

resource "aws_key_pair" "tutorial_kp_final" {
  key_name   = "tutorial_kp_final"
  public_key = file("tutorial_kp.pub")
  //public_key = file("/Users/grimanesa/.ssh/aws_ec2_terraform_key.pub")
}



//TODO:IMPROVE Key pair - generate differents
# resource "aws_key_pair" "tutorial_kp_final" {
#   key_name   = "b18ca9ef-8959-3ac4-b206-a0985377b41f"
#   public_key = tls_private_key.t.public_key_openssh
# }

# provider "tls" {}
# resource "tls_private_key" "t" {
#   algorithm = "RSA"
# }

# provider "local" {}
# resource "local_file" "key" {
#   content  = tls_private_key.t.private_key_pem
#   filename = "id_rsa"
#   provisioner "local-exec" {
#     command = "chmod 600 id_rsa"
#   }
# }

data "aws_ami" "ubuntu" {
  most_recent = "true"
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "tutorial_web" {
  count                  = var.settings.web_app.count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.settings.web_app.instance_type
  subnet_id              = aws_subnet.tutorial_pub_subnet[count.index].id
  key_name               = aws_key_pair.tutorial_kp_final.key_name
  vpc_security_group_ids = [aws_security_group.tutorial_web_sg.id]
  tags = {
    Name = "tutorial_web_${count.index}"
  }
  user_data = file("init.sh")
  //Review depends_on
  depends_on = [
    aws_db_instance.tutorial_db
  ]

}

resource "aws_eip" "tutorial_web_eip" {
  count    = var.settings.web_app.count
  instance = aws_instance.tutorial_web[count.index].id
  vpc      = true
  tags = {
    Name = "tutorial_web_eip_${count.index}"
  }
}
