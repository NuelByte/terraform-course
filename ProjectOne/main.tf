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
  tags       = { "Name" : "${var.env.prefix}_rtb" }
}

resource "aws_internet_gateway" "project_one_igw" {
  vpc_id = aws_vpc.project_one_vpc.id
  tags       = { "Name" : "${var.env.prefix}_igw" }
}