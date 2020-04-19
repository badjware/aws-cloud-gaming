# aws-cloud-gaming

Provision an AWS EC2 instance with a graphic card to play games in the cloud. Uses terraform to create the required infrastructure and a cloud-init script to install the applications on the instance. Once configured, games can be streamed from the instance with low-latency using [Parsec](https://parsecgaming.com/).

Currently only compatible with AWS g4 instance family.

**These scripts creates resources in AWS and your credit card WILL be charged for them. Be sure to review changes before applying them.**

## Features

### Infrastructure
* No fidling with key pairs. A random Administrator password is saved in SSM, set on boot, and retrievable with terraform.
* Restrictive security group. Allow ingress to RDP (port 3389) and VNC (port 5900) only from the computer that created the instance.
* Use a spot instances for around 50% to 70% cost saving compared to an on-demand instance.

### Instance provisionning
* Automatic download of the [Parsec-Cloud-Preparation-Tool](https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool) and run it on first login.
* Automatic configuration of auto-login.
* Install the latest Nvidia vGaming driver.
* Install [Steam](https://store.steampowered.com/).

## Getting started
See the [in-depth guide](./docs/getting_started.md).

tl;dr:
``` bash
# Assuming terraform, powershell, curl, and aws credentials are installed

# Set the desired region and create the infra 
echo 'region = "us-east-1"' >terraform.tfvars
terraform apply

# Get the Administrator password
terraform output instance_password

# Connect with RDP to configure parsec
./connect_with_rdp.ps1
```

## (Advanced) Using as a terraform module
This repository can be used as a terraform module. One use-case would be to attach an extra volume to the instance to store games.
``` terraform
local {
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
    allowed_availability_zone_identifier = [availability_zone_identifier]
    # We won't need much space on our root block device
    root_block_device_size_gb = 30
}

resource "aws_ebs_volume" "games_volume" {
    availability_zone = local.availability_zone
    size = 200
}

resource "aws_volume_attachment" "game_volume_attachment" {
    device_name = "/dev/sdb"
    volume_id   = "${aws_ebs_volume.games_volume.id}"
    instance_id = "${cloud_gaming.instance_id}"
}
```