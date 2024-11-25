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

resource "aws_vpc" "prometheus_vpc" {
  tags       = { "Name" : "${var.env.prefix}_vpc" }
  cidr_block = "${var.aws_config.cidr_block.vpc[0]}/${var.aws_config.cidr_block.vpc[1]}"
}

resource "aws_subnet" "prometheus_subnet_1" {
  tags              = { "Name" : "${var.env.prefix}_subnet_1" }
  vpc_id            = aws_vpc.prometheus_vpc.id
  cidr_block        = "${var.aws_config.cidr_block.subnet[0]}/${var.aws_config.cidr_block.subnet[1]}"
  availability_zone = "${var.aws_config.region}${var.aws_config.az}"
}

resource "aws_route_table" "prometheus_route_table" {
  vpc_id = aws_vpc.prometheus_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prometheus_igw.id
  }
  tags = { "Name" : "${var.env.prefix}_rtb" }
}

resource "aws_internet_gateway" "prometheus_igw" {
  vpc_id = aws_vpc.prometheus_vpc.id
  tags   = { "Name" : "${var.env.prefix}_igw" }
}

resource "aws_route_table_association" "project-one-rta" {
  subnet_id      = aws_subnet.prometheus_subnet_1.id
  route_table_id = aws_route_table.prometheus_route_table.id
}

resource "aws_security_group" "prometheus_sg" {
  name   = "${var.env.prefix}_prom_sec_grp"
  vpc_id = aws_vpc.prometheus_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
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

resource "aws_security_group" "node_exporter_sg" {
  name   = "${var.env.prefix}_node_sec_grp"
  vpc_id = aws_vpc.prometheus_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
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
#   value = data.aws_ami.ubuntu_22
# }

data "aws_ami" "ubuntu_22" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "description"
    values = ["* 22.04 LTS*"]
  }
}

resource "aws_instance" "prometheus_server" {
  ami                         = data.aws_ami.ubuntu_22.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.prometheus_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.prometheus_sg.id]
  availability_zone           = "${var.aws_config.region}${var.aws_config.az}"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.server_key_pair.key_name
  tags = {
    Name = "${var.env.prefix}_prometheus_server"
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.private_key_location)
  }

  provisioner "file" {
    source = "prom_config.service"
    destination = "/home/ubuntu/prom_config.service"
  }

    provisioner "file" {
    source = "entry-point.sh"
    destination = "/home/ubuntu/entry-point.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /home/ubuntu/entry-point.sh",
      ]
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> server_ips.txt"
  }
}

resource "aws_instance" "client_server_1" {
  ami                         = data.aws_ami.ubuntu_22.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.prometheus_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.node_exporter_sg.id]
  availability_zone           = "${var.aws_config.region}${var.aws_config.az}"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.server_key_pair.key_name
  tags = {
    Name = "${var.env.prefix}_client_server_1"
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.private_key_location)
  }

  provisioner "file" {
    source = "node_xporter.service"
    destination = "/home/ubuntu/node_xporter.service"
  }

  provisioner "file" {
    source = "entry-point_node_exporter.sh"
    destination = "/home/ubuntu/entry-point_node_exporter.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /home/ubuntu/entry-point_node_exporter.sh",
      ]
  }
  provisioner "local-exec" {
    command = "echo Client Server 1: ${self.public_ip} >> server_ips.txt"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

output "ec_ip_address" {
  value = aws_instance.prometheus_server.public_ip
}

resource "aws_key_pair" "server_key_pair" {
  key_name   = "${var.env.prefix}_key_pair"
  public_key = file(var.public_key_location)
}

variable "public_key_location" {
  description = "Path to public key for configuring SSH access"
}
variable "private_key_location" {
  description = "Path to private key for configuring instance using remote-exec"
}