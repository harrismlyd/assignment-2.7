locals {
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnets[0]
}

variable "name" {
  description = "name of application"
  type        = string
  default     = "harris"
}

resource "aws_instance" "public" {
  ami                         = "ami-04c913012f8977029"
  instance_type               = "t2.micro"
  subnet_id                   = local.public_subnet_id
  associate_public_ip_address = true
  key_name                    = "harris-key-pair" #Change to your keyname, e.g. jazeel-key-pair
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "${var.name}-ec2" #Prefix your own name, e.g. jazeel-ec2
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.my_ebs_volume.id
  instance_id = aws_instance.public.id
}

resource "aws_ebs_volume" "my_ebs_volume" {
  availability_zone = "ap-southeast-1a"  # Change to your desired AZ
  size              = 1               # Size in GiB
  tags = {
    Name = "harris-ebs-volume"
  }
}

resource "aws_security_group" "allow_ssh" {
  name_prefix = "${var.name}-terraform-security-group" #Security group name, e.g. jazeel-terraform-security-group
  description = "Allow SSH inbound"
  vpc_id      = local.vpc_id #VPC ID (Same VPC as your EC2 subnet above), E.g. vpc-xxxxxxx
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "49.245.72.177/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

output "public_ip" {
  value = aws_instance.public.public_ip
}

output "public_dns" {
  value = aws_instance.public.public_dns
}