terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws"{
    region = "us-east-1"
}

resource "aws_default_vpc" "default"{

}

data "aws_subnet_ids" "default_subnets" {
  vpc_id = aws_default_vpc.default.id
}

resource "aws_security_group" "http_server_sg"{
    name = "http_server_sg"
    vpc_id = aws_default_vpc.default.id

        ingress {
            from_port=80
            to_port=80
            protocol="tcp"
            cidr_blocks=["0.0.0.0/0"]
        }

        ingress {
            from_port=22
            to_port=22
            protocol="tcp"
            cidr_blocks=["0.0.0.0/0"]
        }
        egress {
            from_port=0
            to_port=0
            protocol=-1
            cidr_blocks=["0.0.0.0/0"]

            }

            
}
data "aws_ami" "aws_linux_2_latest"{
  most_recent=true
  owners=["amazon"]
  filter{
    name="name"
    values=["amzn2-ami-hvm-*"]
  }
}
resource "aws_instance" "http_server"{
  ami=data.aws_ami.aws_linux_2_latest.id
  key_name="terraform"
  instance_type="t2.micro"
  vpc_security_group_ids=[aws_security_group.http_server_sg.id]
  subnet_id=tolist(data.aws_subnet_ids.default_subnets.ids)[0]

user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y 
sudo systemctl enable nginx
sudo systemctl start nginx
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

EOF

}