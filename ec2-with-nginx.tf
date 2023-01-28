# Declaring Requred Providor

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Using Providor AWS and definig region

provider "aws" {
  region = "us-east-1"
}

# To Get Default VPC in selected region

resource "aws_default_vpc" "default" {

}

# To Get Subnet ID

data "aws_subnet_ids" "default_subnets" {
  vpc_id = aws_default_vpc.default.id
}

# Creating Security Group for Allowing HTTP and SSH Ports Also Allowing Internet Connection to EC2 Instanse

resource "aws_security_group" "http_server_sg" {
  name   = "http_server_sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]

  }


}

# To Get Letest AMI ID for AMAZON LINUX

data "aws_ami" "aws_linux_2_latest" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

# Creation of EC2 instance with installation of NGINX using User Data
resource "aws_instance" "http_server" {
  ami                    = data.aws_ami.aws_linux_2_latest.id
  key_name               = "terraform"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.http_server_sg.id]
  subnet_id              = tolist(data.aws_subnet_ids.default_subnets.ids)[0]

  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y 
sudo systemctl enable nginx
sudo systemctl start nginx
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

EOF

}
