terraform {
  backend "s3" {
    bucket = "nilenso-rubberduck"
    key = "setup/rubberduck.tfstate"
    region = "ap-south-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_key_pair" "rubberduck" {
  key_name = "rubberduck"
}

resource "aws_budgets_budget" "monthly_budget" {
  name              = "monthly-budget"
  budget_type       = "COST"
  limit_amount      = "100"
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["bills@nilenso.com"]
  }
}


resource "aws_instance" "llama_instance" {
  instance_type = "inf1.2xlarge"
  ami = "ami-026ebaaa7f5422703"

  tags = {
    Name = "llama-inference-instance"
    Application = "inference"
  }

  # You may need to specify a key pair for SSH access
  key_name = data.aws_key_pair.rubberduck.key_name

  # If you have a specific VPC and subnet, specify them here
  # vpc_security_group_ids = [aws_security_group.llama_sg.id]
  # subnet_id     = aws_subnet.llama_subnet.id

  root_block_device {
    volume_type = "gp3"
    volume_size = 100  # Adjust based on your storage needs
  }
}

resource "aws_ec2_instance_state" "llama_instance_state" {
  instance_id = aws_instance.llama_instance.id
  state = "running"
}
