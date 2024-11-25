az = "us-east-1a"
env = {
  name   = "Monitoring"
  prefix = "mon"
}
subnet_cidr_block = "10.0.30.0/24"
vpc_cidr_block    = "10.0.0.0/16"

aws_config = {
  az     = "b"
  region = "us-east-1"
  cidr_block = {
    vpc    = ["10.0.0.0", "16"]
    subnet = ["10.0.20.0", "24"]
  }
}

allowed_ips = ["0.0.0.0/0"]

public_key_location  = "~/.ssh/id_rsa.pub"
private_key_location = "~/.ssh/id_rsa"