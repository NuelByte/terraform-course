provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "devops-vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = { "Name" : "demo-vpc" }
}

resource "aws_subnet" "devops-subnet" {
  vpc_id            = aws_vpc.devops-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags              = { "Name" : "demo-subnet" }
}

data "aws_vpc" "already_exisiting_vpc" {
  default = true
  state   = "available"
}

# resource "aws_subnet" "devops-subnet-2" {
#   tags              = { "Name" : "devops-subnet-2" }
#   vpc_id            = data.aws_vpc.already_exisiting_vpc.id
#   cidr_block        = "172.31.96.0/20"
#   availability_zone = "us-east-1a"
# }

output "devops-vpc-id" {
  value = aws_vpc.devops-vpc.id
}

output "devops-subnet1-id" {
  value = aws_subnet.devops-subnet.id
}

