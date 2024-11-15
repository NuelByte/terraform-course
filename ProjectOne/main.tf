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
  name   = "${var.env.prefix}_sec_grp"
  vpc_id = aws_vpc.project_one_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = { "Name" : "${var.env.prefix}_sg" }
}

variable "allowed_ips" {
  type        = list(string)
  description = "Allowed IPs for aws_security_group"
  default     = ["0.0.0.0/0"]
}

# output "aws_ami" {
#   value = data.aws_ami.latest_amazon_linux
# }

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "description"
    values = ["Amazon Linux*AMI*", ]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel*-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "project_one_server" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.project_one_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.project_one_sg.id]
  availability_zone           = "${var.aws_config.region}${var.aws_config.az}"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.project_one_key_pair.key_name
  tags = {
    Name = "${var.env.prefix}_nginx_web_server"
  }
  # user_data = file("entry-point.sh")
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_location)
  }

  provisioner "remote-exec" {
    # inline = [
    #     "#!/bin/bash",
    #     "sudo yum update -y",
    #     "echo 'I am awesome' > ~/readme.txt",
    #   ]
    script = "entry-point.sh"
  }
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> server_ips.txt"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

output "ec_ip_address" {
  value = aws_instance.project_one_server.public_ip
}

resource "aws_key_pair" "project_one_key_pair" {
  key_name   = "${var.env.prefix}_key_pair"
  public_key = file(var.public_key_location)
}

variable "public_key_location" {
  description = "Path to public key for configuring SSH access"
}
variable "private_key_location" {
  description = "Path to private key for configuring instance using remote-exec"
}