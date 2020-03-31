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

resource "random_password" "password" {
  length = 32
  special = true
}

resource "aws_ssm_parameter" "password" {
  name = "cloud-gaming-administrator-password"
  type = "SecureString"
  value = random_password.password.result

  tags = {
    App = "aws-cloud-gaming"
  }
}

resource "aws_security_group" "default" {
  name = "cloud-gaming-sg"

  tags = {
    App = "aws-cloud-gaming"
  }
}

# Allow rdp connections from the local ip
resource "aws_security_group_rule" "rdp_ingress" {
  type = "ingress"
  description = "Enable rdp connections via 3389"
  from_port = 3389
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

resource "aws_iam_role" "windows_instance_role" {
  name = "cloud-gaming-instance-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    App = "aws-cloud-gaming"
  }
}

resource "aws_iam_policy" "password_get_parameter_policy" {
  name = "password-get-parameter-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ssm:GetParameter",
      "Resource": "${aws_ssm_parameter.password.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "password_get_parameter_policy_attachment" {
  role = aws_iam_role.windows_instance_role.name
  policy_arn = aws_iam_policy.password_get_parameter_policy.arn
}

resource "aws_iam_instance_profile" "windows_instance_profile" {
  name = "cloud-gaming-instance-profile"
  role = aws_iam_role.windows_instance_role.name
}

resource "aws_instance" "windows_instance" {
  instance_type = var.aws_instance_type
  ami = data.aws_ami.windows_ami.image_id
  security_groups = [aws_security_group.default.name]
  user_data = templatefile("${path.module}/user_data.tpl", { password_parameter_name = aws_ssm_parameter.password.name })
  iam_instance_profile = aws_iam_instance_profile.windows_instance_profile.id

  tags = {
    Name = "cloud-gaming-instance"
    App = "aws-cloud-gaming"
  }
}
