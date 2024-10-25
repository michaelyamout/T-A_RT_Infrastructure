variable "aws_region" {
  description = "AWS region to deploy infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID"
  type        = string
  default     = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS AMI ID for us-east-1
}

variable "your_ip" {
  description = "Your IP address for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
