provider "aws" {
  region = "us-east-1"
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
  cidr_block = var.vpc_cidr_block
}


resource "aws_subnet" "project_one_subnet_1" {
  tags              = { "Name" : "${var.env.prefix}_subnet_1" }
  vpc_id            = aws_vpc.project_one_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = var.az
}
