provider "aws" {
  region = var.aws_config.region
}

variable "vpc_cidr_block" {
  description = "cidr block value for vpc"
}

variable "subnet_cidr_block" {
  description = "cidr block value for subnet"
}

variable "az" {
  description = "Availability zone where subnet would be created"
}

variable "env" {
  description = "deployment environment details"
  type = object({
    name   = string
    prefix = string
  })
  default = {
    name   = "development"
    prefix = "dev"
  }
}

variable "aws_config" {
  description = "Required configuration values"
  type = object({
    region = string
    az     = string
    cidr_block = object({
      vpc    = list(string)
      subnet = list(string)
    })
  })
}

resource "aws_vpc" "project_one_vpc" {
  tags       = { "Name" : "${var.env.prefix}_vpc" }
  cidr_block = "${var.aws_config.cidr_block.vpc[0]}/${var.aws_config.cidr_block.vpc[1]}"
}

resource "aws_subnet" "project_one_subnet_1" {
  tags              = { "Name" : "${var.env.prefix}_subnet_1" }
  vpc_id            = aws_vpc.project_one_vpc.id
  cidr_block        = "${var.aws_config.cidr_block.subnet[0]}/${var.aws_config.cidr_block.subnet[1]}"
  availability_zone = "${var.aws_config.region}${var.aws_config.az}"
}

resource "aws_route_table" "project_one_route_table" {
  vpc_id = aws_vpc.project_one_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_one_igw.id
  }
  tags = { "Name" : "${var.env.prefix}_rtb" }
}

resource "aws_internet_gateway" "project_one_igw" {
  vpc_id = aws_vpc.project_one_vpc.id
  tags   = { "Name" : "${var.env.prefix}_igw" }
}

resource "aws_route_table_association" "project-one-rta" {
  subnet_id      = aws_subnet.project_one_subnet_1.id
  route_table_id = aws_route_table.project_one_route_table.id
}

# resource "aws_default_route_table" "project_one_main_rtb" {
#   default_route_table_id = aws_vpc.project_one_vpc.default_route_table_id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.project_one_igw.id
#   }
#   tags = { "Name" : "${var.env.prefix}_main_rtb" }
# }

resource "aws_security_group" "project_one_sg" {
  name = "${var.env.prefix}_sec_grp"
  vpc_id = aws_vpc.project_one_vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
}

variable "allowed_ips" {
  type = list(string)
  description = "Allowed IPs for aws_security_group"
  default = ["0.0.0.0/0"]
}
