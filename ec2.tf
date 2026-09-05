resource "aws_security_group" "instance_sg" {
  name        = "cloudops-instance-sg"
  description = "Allow inbound SSH and HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP App"
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

  tags = {
    Name = "cloudops-instance-sg"
  }
}

# Fetch latest Amazon Linux 2023 AMI reliably using official owner ID and explicit filters
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"] # Official Amazon AWS account ID

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "primary" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  key_name               = "kv"
  
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              cat << 'EOT' > /usr/share/nginx/html/index.html
              <html>
                <head><title>CloudOps Auto-Healing Active</title></head>
                <body>
                  <h1>CloudOps Auto-Healing & Disaster Recovery Pipeline</h1>
                  <p>Status: ONLINE and Auto-Configured via User Data!</p>
                </body>
              </html>
              EOT
              EOF

  tags = {
    Name        = "cloudops-primary-instance"
    Environment = "production"
  }
}

resource "local_file" "ansible_inventory" {
  content  = <<-EOT
    [webservers]
    ${aws_instance.primary.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=./kv.pem
  EOT
  filename = "${path.module}/hosts.ini"
}

output "primary_instance_ip" {
  value       = aws_instance.primary.public_ip
  description = "Public IP of the primary workload server"
}