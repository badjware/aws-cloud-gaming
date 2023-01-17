provider "aws" {
  region = var.region
}

data "aws_ami" "windows_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}

data "external" "local_ip" {
  # curl should (hopefully) be available everywhere
  program = ["curl", "https://api.ipify.org?format=json"]
}

locals {
  availability_zone = "${var.region}${element(var.allowed_availability_zone_identifier, random_integer.az_id.result)}"
}

resource "random_integer" "az_id" {
  min = 0
  max = length(var.allowed_availability_zone_identifier)
}

resource "random_password" "password" {
  length  = 32
  special = true
}

resource "aws_ssm_parameter" "password" {
  name  = "${var.resource_name}-administrator-password"
  type  = "SecureString"
  value = random_password.password.result

  tags = {
    App = "aws-cloud-gaming"
  }
}

resource "aws_security_group" "default" {
  name = "${var.resource_name}-sg"

  tags = {
    App = "aws-cloud-gaming"
  }
}

# Allow rdp connections from the local ip
resource "aws_security_group_rule" "rdp_ingress" {
  type              = "ingress"
  description       = "Allow rdp connections (port 3389)"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["${data.external.local_ip.result.ip}/32"]
  security_group_id = aws_security_group.default.id
}

# Allow vnc connections from the local ip
resource "aws_security_group_rule" "vnc_ingress" {
  type              = "ingress"
  description       = "Allow vnc connections (port 5900)"
  from_port         = 5900
  to_port           = 5900
  protocol          = "tcp"
  cidr_blocks       = ["${data.external.local_ip.result.ip}/32"]
  security_group_id = aws_security_group.default.id
}


# Allow outbound connection to everywhere
resource "aws_security_group_rule" "default" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}

resource "aws_iam_role" "windows_instance_role" {
  name               = "${var.resource_name}-instance-role"
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
  name   = "${var.resource_name}-password-get-parameter-policy"
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

data "aws_iam_policy" "driver_get_object_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "password_get_parameter_policy_attachment" {
  role       = aws_iam_role.windows_instance_role.name
  policy_arn = aws_iam_policy.password_get_parameter_policy.arn
}

resource "aws_iam_role_policy_attachment" "driver_get_object_policy_attachment" {
  role       = aws_iam_role.windows_instance_role.name
  policy_arn = data.aws_iam_policy.driver_get_object_policy.arn
}

resource "aws_iam_instance_profile" "windows_instance_profile" {
  name = "${var.resource_name}-instance-profile"
  role = aws_iam_role.windows_instance_role.name
}

resource "aws_spot_instance_request" "windows_instance" {
  instance_type     = var.instance_type
  availability_zone = local.availability_zone
  ami               = (length(var.custom_ami) > 0) ? var.custom_ami : data.aws_ami.windows_ami.image_id
  security_groups   = [aws_security_group.default.name]
  user_data = var.skip_install ? "" : templatefile("${path.module}/templates/user_data.tpl", {
    password_ssm_parameter = aws_ssm_parameter.password.name,
    var = {
      instance_type               = var.instance_type,
      install_parsec              = var.install_parsec,
      install_auto_login          = var.install_auto_login,
      install_graphic_card_driver = var.install_graphic_card_driver,
      install_steam               = var.install_steam,
      install_gog_galaxy          = var.install_gog_galaxy,
      install_origin              = var.install_origin,
      install_epic_games_launcher = var.install_epic_games_launcher,
      install_uplay               = var.install_uplay,
    }
  })
  iam_instance_profile = aws_iam_instance_profile.windows_instance_profile.id

  # Spot configuration
  spot_type            = "one-time"
  wait_for_fulfillment = true

  # EBS configuration
  ebs_optimized = true
  root_block_device {
    volume_size = var.root_block_device_size_gb
  }

  tags = {
    Name = "${var.resource_name}-instance"
    App  = "aws-cloud-gaming"
  }
}

output "instance_id" {
  value = aws_spot_instance_request.windows_instance.spot_instance_id
}

output "instance_ip" {
  value = aws_spot_instance_request.windows_instance.public_ip
}

output "instance_public_dns" {
  value = aws_spot_instance_request.windows_instance.public_dns
}

output "instance_password" {
  value     = random_password.password.result
  sensitive = true
}
