provider "aws" {
  region = "eu-north-1"  # Stockholm region
}

variable "ami_id" {
  # Ubuntu 22.04 LTS AMI in eu-north-1
  default = "ami-0a716d3f3b16d290c"
}

variable "instance_type" {
  default = "t3.micro"
}

# Generate a new SSH key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create AWS key pair with a unique name
resource "aws_key_pair" "deployer" {
  key_name   = "terraform-key-001"  # Unique name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# Security group to allow SSH and HTTP
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create 2 EC2 instances
resource "aws_instance" "web" {
  count         = 2
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "WebServer-${count.index + 1}"
  }
}

# Output public IPs
output "web_instance_ips" {
  value = aws_instance.web[*].public_ip
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/terraform-key-001.pem"
  file_permission = "0600"
}
