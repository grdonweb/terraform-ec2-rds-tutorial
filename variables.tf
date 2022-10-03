// This variables is to set the AWS region
// that everything will be created in
variable "aws_region" {
  default = "eu-central-1"
}

// This variables is to set profile credentials of AWS will be used
variable "aws_profile" {
  default = "grima_aws"
}

// This varibales is to set the CIDR block for the VPC
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

// This variables holds the number of public / private hosts
variable "subnet_count" {
  description = "Number of subnets"
  type        = map(number)
  default = {
    public  = 1,
    private = 2
  }
}

// This variables contains CIDR blocks for public subnets (4 for this tutorial)
variable "public_subnet_cidr_blocks" {
  description = "Available CIDR blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}


// This variables contains CIDR blocks for private subnets (4 for this tutorial)
variable "private_subnet_cidr_blocks" {
  description = "Available CIDR blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24"
  ]
}

variable "settings" {
  description = "Configuration settings"
  type        = map(any)
  default = {
    "database" = {
      allocated_storage   = 10
      engine              = "mysql"
      engine_version      = "8.0.27"
      instance_class      = "db.t2.micro"
      db_name             = "tutorial"
      skip_final_snapshot = true
    },
    "web_app" = {
      count         = 1
      instance_type = "t2.micro" //ec2 instances
    }
  }
}

// This variables contains the database user
// Stored in a secrets file
// @TODO
variable "db_username" {
  description = "Database master user"
  type        = string
  sensitive   = true
}

# // This variables contains the database user password
# // Stored in a secrets file
// @TODO
variable "db_password" {
  description = "Database master user password"
  type        = string
  sensitive   = true
}
