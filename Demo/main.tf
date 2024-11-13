provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "devops-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "devops-subnet" {
  vpc_id            = aws_vpc.devops-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
}
