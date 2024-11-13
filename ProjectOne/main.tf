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
