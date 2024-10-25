provider "aws" {
  region = var.aws_region
}

# VPC and Network Configuration
resource "aws_vpc" "red_team_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "Red Team VPC"
  }
}

resource "aws_internet_gateway" "red_team_igw" {
  vpc_id = aws_vpc.red_team_vpc.id
  tags = {
    Name = "Red Team IGW"
  }
}

resource "aws_subnet" "red_team_subnet" {
  vpc_id                  = aws_vpc.red_team_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "Red Team Subnet"
  }
}

resource "aws_route_table" "red_team_rt" {
  vpc_id = aws_vpc.red_team_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.red_team_igw.id
  }
  tags = {
    Name = "Red Team Route Table"
  }
}

resource "aws_route_table_association" "red_team_rta" {
  subnet_id      = aws_subnet.red_team_subnet.id
  route_table_id = aws_route_table.red_team_rt.id
}


resource "aws_security_group" "red_team_sg" {
  name        = "red-team-sg"
  description = "Security group for Red Team infrastructure"
  vpc_id      = aws_vpc.red_team_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.your_ip}/32"]
    description = "SSH from your IP"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Internal SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  ingress {
    from_port   = 31337
    to_port     = 31337
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Sliver C2 internal communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "Red Team Security Group"
  }
}

# Add the new rule as a separate resource
resource "aws_security_group_rule" "ssh_from_attacker_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${aws_instance.attacker_workstation.public_ip}/32"]
  security_group_id = aws_security_group.red_team_sg.id
  description       = "SSH from attacker workstation public IP"
}





# SSH Key Configuration
resource "aws_key_pair" "red_team_key" {
  key_name   = "red-team-key"
  public_key = file("${path.module}/id_rsa.pub")
}

# EC2 Instances
resource "aws_instance" "sliver_c2" {
  ami                         = var.ami_id
  instance_type              = "t2.micro"
  key_name                   = aws_key_pair.red_team_key.key_name
  vpc_security_group_ids     = [aws_security_group.red_team_sg.id]
  subnet_id                  = aws_subnet.red_team_subnet.id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "Sliver C2 Server"
  }
}

resource "aws_instance" "redirector" {
  ami                         = var.ami_id
  instance_type              = "t2.micro"
  key_name                   = aws_key_pair.red_team_key.key_name
  vpc_security_group_ids     = [aws_security_group.red_team_sg.id]
  subnet_id                  = aws_subnet.red_team_subnet.id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "Redirector"
  }
}

resource "aws_instance" "attacker_workstation" {
  ami                         = var.ami_id
  instance_type              = "t2.micro"
  key_name                   = aws_key_pair.red_team_key.key_name
  vpc_security_group_ids     = [aws_security_group.red_team_sg.id]
  subnet_id                  = aws_subnet.red_team_subnet.id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "Attacker Workstation"
  }
}
