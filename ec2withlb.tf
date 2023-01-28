# Declaring Requred Providor

#terraform {
#  required_providers {
#    aws = {
#      source  = "hashicorp/aws"
#      version = "~> 4.0"
#    }
#  }
#}

# Using Providor AWS and definig region

#provider "aws" {
#  region = "us-east-1"
#}

# To Get Default VPC in selected region

resource "aws_default_vpc" "default" {

}

# To Get Subnet ID

data "aws_subnet_ids" "default_subnets" {
  vpc_id = aws_default_vpc.default.id
}

# Creating Security Group for Allowing HTTP and SSH Ports Also Allowing Internet Connection to EC2 Instanse

resource "aws_security_group" "elb_sg" {
  name   = "elb_sg"
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

# To Get Default Subnets

data "aws_subnets" "default_subnets" {

}
# Creation of EC2 instances with installation of NGINX using User Data

resource "aws_instance" "http_servers" {

  # To Create 3 Instances
  count = 3

  ami                    = data.aws_ami.aws_linux_2_latest.id
  key_name               = "terraform"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.elb_sg.id]
  subnet_id              = toset(data.aws_subnets.default_subnets.ids)[count]

  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y 
sudo systemctl enable nginx
sudo systemctl start nginx
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

EOF

}

# Creating ELB

resource "aws_elb" "elb_sg" {
  name            = "elb"
  subnets         = data.aws_subnet_ids.default_subnets.ids
  security_groups = [aws_security_group.elb_sg.id]
  instences       = values(aws_instance.http_servers).*.id

  # Listner of ELB so that ELB can Listen on these port(s)

  listener {
    listener_port     = 80
    instence_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}
