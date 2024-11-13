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


resource "aws_vpc" "project_one_vpc" {
  tags       = { "Name" : "${var.env.prefix}_vpc" }
  cidr_block = var.vpc_cidr_block
}
