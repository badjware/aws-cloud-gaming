provider "aws" {
  region = var.aws_region
}

data "aws_ami" "windows_ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }
}

data "external" "local_ip" {
  program = ["curl", "https://v4.ident.me/.json"]
}

data "template_file" "user_data" {
  template = "user_data.tlp"
}

resource "aws_security_group" "default" {
  tags = {
    Name = "aws-cloud-gaming-sg"
    App = "aws-cloud-gaming"
  }
}

# Allow rdp connections from the local ip
resource "aws_security_group_rule" "rdp_ingress" {
  type = "ingress"
  from_port = 0
  to_port = 3389
  protocol = "tcp"
  cidr_blocks = ["${data.external.local_ip.result.address}/32"]
  security_group_id = aws_security_group.default.id
}

# Allow outbound connection to everywhere
resource "aws_security_group_rule" "default_egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}

resource "aws_instance" "windows_instance" {
  instance_type = var.aws_instance_type
  ami = data.aws_ami.windows_ami.image_id
  security_groups = [aws_security_group.default.name]
  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "aws-cloud-gaming-instance"
    App = "aws-cloud-gaming"
  }
}
