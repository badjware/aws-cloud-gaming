# aws-cloud-gaming

Provision an AWS EC2 instance with a gpu to play games in the cloud. Uses terraform to create the required infrastructure and a user data script to install the applications on the instance. Once configured, games can be streamed from the instance with low-latency using [Parsec](https://parsecgaming.com/).

The scripts in this repository automate most of the manual operations needed to setup such an instance. The only exception is management of AMIs, which must be done through the AWS management console.

Currently only compatible with g3 and g4 instance family. The script will still run on other instance types, but gpu driver will have to be installed manually.

**These scripts create resources in AWS and your credit card WILL be charged for them. Be sure to review changes before applying them. These scripts come with no warranty of any kind, use them at your own risk.**

## Features

### Infrastructure
* No fiddling with key pairs. A random Administrator password is saved in SSM, set on boot, and retrievable with terraform.
* Restrictive security group. Allow ingress to RDP (port 3389) and VNC (port 5900) only from the computer that created the instance.
* Use a spot instance for around 50% to 70% cost saving compared to an on-demand instance.
* Use the latest Windows Server 2019 AMI available in the region by default, and allow the use of a custom AMI after the inital setup.

### Instance provisioning
* Automatically download of the [Parsec-Cloud-Preparation-Tool](https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool) by [@jamesstringerparsec](https://github.com/jamesstringerparsec) and run it on first login.
* Automatically configure the auto-login.
* Install the latest Nvidia vGaming driver.
* Install [Steam](https://store.steampowered.com/).

Optionally, other launcher than Steam such as GOG Galaxy, Uplay, etc. can be downloaded and installed automatically.

## Getting started
See the [in-depth guide](./docs/getting_started.md).

tl;dr:
``` bash
# Assuming terraform, powershell, curl, and aws credentials are installed

# Set the desired region and create the infra 
echo 'region = "us-east-1"' >terraform.tfvars
terraform init
terraform apply

# Get the instance ip
terraform output instance_ip

# Get the Administrator password
terraform output instance_password
```

## (Advanced) Using as a terraform module
This repository can be used as a terraform module. One use-case would be to attach an extra volume to the instance to store games.
``` terraform
locals {
    region = "us-east-1"
    availability_zone_identifier = "a"
    availability_zone = "${local.region}${local.availability_zone_identifier}"
}

provider "aws" {
  region = local.region
}

module "cloud_gaming" {
    source = "github.com/badjware/aws-cloud-gaming"

    region = local.region
    # The instance and the volume must be on the same AZ
    allowed_availability_zone_identifier = [local.availability_zone_identifier]
    # We won't need much space on our root block device
    root_block_device_size_gb = 40
}

resource "aws_ebs_volume" "games_volume" {
    availability_zone = local.availability_zone
    size = 200
}

resource "aws_volume_attachment" "game_volume_attachment" {
    device_name = "/dev/sdb"
    volume_id   = aws_ebs_volume.games_volume.id
    instance_id = module.cloud_gaming.instance_id
}
```

## Inputs
| Name | Description | Type | Default |
| --- | --- | --- | ---|
| region | The aws region. Choose the one closest to you: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions | `string` | |
| allowed_availability_zone_identifier | The allowed availability zone identify (the letter suffixing the region). Choose ones that allows you to request the desired instance as spot instance in your region. An availability zone will be selected at random and the instance will be booted in it. | `list(string)` | `[]` (all available) |
| instance_type | The aws instance type, Choose one with a CPU/GPU that fits your need: https://aws.amazon.com/ec2/instance-types/#Accelerated_Computing | `string` | "g4dn.xlarge" |
| resource_name | Name with which to prefix resources in AWS | `string` | `cloud-gaming` |
| root_block_device_size_gb | The size of the root block device (C:\\ drive) attached to the instance | `number` | 120 |
| custom_ami | Use the specified ami instead of the most recent windows ami in available in the region | `string` | "" |
| skip_install | Skip installation step on startup. Useful when using a custom AMI that is already setup | `bool` | false |
| install_parsec | Download and run Parsec-Cloud-Preparation-Tool on first login | `bool` | true |
| install_auto_login | Configure auto-login on first boot | `bool` | true |
| install_graphic_card_driver | Download and install the Nvidia driver on first boot | `bool` | true |
| install_steam | Download and install Valve Steam on first boot | `bool` | true |
| install_gog_galaxy | Download and install GOG Galaxy on first boot | `bool` | false |
| install_uplay | Download and install Ubisoft Uplay on first boot | `bool` | false |
| install_origin | Download and install EA Origin on first boot | `bool` | false |
| install_epic_games_launcher | Download and install EPIC Games Launcher on first boot | `bool` | false |


## Outputs
| Name | Description | Type |
| --- | --- | --- |
| instance_id | The id of the instance | `string` |
| instance_ip | The ip address of the instance. Use it to connect | `string` |
| instance_public_dns | The dns address of the instance. Use it to connect | `string` |
| instance_password | The Administrator password of the instance. Use it to connect | `string` |
