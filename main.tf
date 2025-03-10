provider "aws" {
  region = "ap-southeast-2" # Sydney region
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-demo-rsherman-dl0ap1pj"
    key            = "ec2-demo/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}

# Get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get the default subnet in the first availability zone
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create a security group
resource "aws_security_group" "allow_ssh" {
  name_prefix = "allow_ssh_managed_"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# Create EC2 instance
resource "aws_instance" "ubuntu_free" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro" # Free tier eligible instance type
  subnet_id     = tolist(data.aws_subnets.default.ids)[0]

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "Ubuntu-Free-Tier"
  }

  root_block_device {
    volume_size = 8 # Free tier eligible storage
    volume_type = "gp2"
  }
} 