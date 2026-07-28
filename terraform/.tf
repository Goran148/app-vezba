# 1. POSTAVKA PROVAJDERA I VERZIJA
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Stabilna AWS verzija
    }
  }
}

provider "aws" {
  region = "eu-central-1" # Frankfurt (najmanja latencija za Srbiju)
}

# 2. MREŽA (VPC, Subnet, Internet Gateway)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "devops-projekat-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["eu-central-1a"]
  public_subnets = ["10.0.1.0/24"]

  # ISKLJUČENI NAT I VPN GATEWAY:
  # Ostavljamo ih na false da ti AWS ne bi naplatio ~$30 mesečno.
  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Environment = "dev"
    Project     = "DevOps-Vezba"
  }
}

# 3. BEZBEDNOSNA GRUPA (Security Group za požarni zid)
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "flask-app-sg"
  description = "Dozvoljava SSH i port 5000 za Flask aplikaciju"
  vpc_id      = module.vpc.vpc_id

  # Ulazni saobraćaj (Ingress)
  ingress_with_cidr_blocks = [
    {
      from_port   = 5000
      to_port     = 5000
      protocol    = "tcp"
      description = "Flask Web App"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH Access"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # Izlazni saobraćaj (Egress) - instanca može da skida Docker slike sa interneta
  egress_rules = ["all-all"]

  tags = {
    Environment = "dev"
    Project     = "DevOps-Vezba"
  }
}

# 4. SERVER (EC2 Instanca)
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "devops-flask-server"

  instance_type               = "t2.micro" # Besplatno u AWS Free Tier-u (može i t3.micro)
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true

  # Automatska instalacija Docker-a na serveru prilikom kreiranja
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Environment = "dev"
    Project     = "DevOps-Vezba"
  }
}

# 5. OUTPUTS (Prikaz u terminalu nakon završetka)
output "ec2_public_ip" {
  description = "Javna IP adresa tvoje EC2 instance"
  value       = module.ec2_instance.public_ip
}