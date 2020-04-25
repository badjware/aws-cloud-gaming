# Getting Started

**These scripts create resources in AWS and your credit card WILL be charged for them. Be sure to review changes before applying them. These scripts come with no warranty of any kind, use them at your own risk.**

## 1. Install prerequisite

Download and extract the [zip archive of this repository](https://github.com/badjware/aws-cloud-gaming/archive/master.zip) somewhere on your system.

### Windows
Download and install [Parsec](https://parsecgaming.com/downloads/).

Download and install the following in your PATH:
* [curl](https://curl.haxx.se/windows/)
* [terraform](https://www.terraform.io/downloads.html)

Alternatively, it may be simpler to install them with [chocolatey](https://chocolatey.org). To do so, open powershell as an administrator and paste the following commands:
``` powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install curl
choco install terraform
```

You can confirm that both commands are correctly installed by opening a new powershell window and typing in the following commands:
```
terraform --version
curl --version
```

### Linux
If you are using Linux, install the following using your distribution's package manager:
* `curl` (often already present in a default installation)
* `terraform`
* [remmina](https://remmina.org/) with the RDP plugin, or some other way to connect with RDP
* [parsec](https://parsecgaming.com/downloads/)

In addition, you can optionally install `powershell` to be able to execute the helper scripts.

## 2. Configure

### 2.1 AWS credentials configuration
Login to your AWS console and follow the [documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) to create a new access key. If you need to create a new user, create one with the `AdministratorAccess` permissions policy.

Once you have your access key id and your secret access key, run the script `configure_aws_credentials.ps1` and provide them when prompted.

Alternatively, create the file `%UserProfile%\.aws\credentials` on Windows, or `~/.aws/credentials` on Linux and place the following content:
``` ini
[default]
aws_access_key_id = <your_access_key_id>
aws_secret_access_key = <your_secret_access_key>
```

### 2.2 Terraform configuration
Rename the file `terraform.tfvars.exemple` to `terraform.tfvars`. Edit it to set the region in which you wish to boot your instance. You can test which region will give you the best ping with sites like this one: https://cloudpingtest.com/aws

By default, terraform will attach an EBS volume of 120GB to the instance, which should hopefully be able to hold 1 game. If you require more disk space, uncomment the line with `root_block_device_size_gb` and set the value to your liking.

## 3. Setup the instance
You are now ready to boot your gaming instance!

1. Open a terminal/powershell in the folder where you unzipped the content of this repository and type in the following command:
``` bash
terraform init
terraform apply
```

2. Review the changes and type in `yes` when ready. **Important: this is the step where you will be charged for the resources created in AWS by terraform!**

3. Wait for the instance to boot up. It may take a few minutes for the user data script to set the correct password, so be patient.

4. To connect to the machine, run the script `copy_administrator_password.ps1` to place the password in your clipboard and `connect_with_rdp.ps1` to start your rdp client with the ip and user already filled in. Simply paste the password when prompted.<br><br>
Alternatively, you can use the command `terraform output instance_ip` to get the ip of your instance and `terraform output instance_password` to get your password. The user is `Administrator`. Connect to the instance with your RDP client using these information.

5. Once connected, [Parsec-Cloud-Preparation-Tool](https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool) will automatically start. Follow the steps until completion. You can skip installing the Nvidia driver and the auto-login, it should already have been done for you by the user data script.

6. Once Parsec-Cloud-Preparation-Tool complete, connect to your Parsec account on the instance and reboot. From now on, use Parsec instead of RDP to connect to your machine.

You now completed setting up your instance and ready to install and play games! However, the data that you write on the disk is not persistent and will be lost when you shutdown the machine. Continue to the next step to create an AMI and avoid reinstalling your instance each time you want to play games.

**You are charged by the hour, so don't forget to shutdown your instance when you are done!**

## 4. Install your games and create an AMI

The volume attached to the instance is destroyed when the instance is terminated. We could add an additional persistent EBS volume to conserve data between reboots, but AWS charges for the volume even when it's not in use. It's more cost-effective to configure the instance, create a custom AMI, and use this AMI to start the machine. **AWS still charges for the storage used up by the AMI, but the rate is much lower than an EBS volume.** In us-east-1, a gp2 EBS volume costs 0.11$/GB-month compared to an EBS snapshot (an AMI is made up of one or many EBS snapshots) costs 0.05$/GB-month. [source](https://aws.amazon.com/ebs/pricing/)

1. Before creating an AMI, prepare your instance so it's in a state that you want it to be. For example, install your games, launchers, log into your accounts, etc.

2. Log into the AWS console and navigate to the [list of EC2 instances](https://console.aws.amazon.com/ec2/v2/home#Instances). If you don't see your instance, make sure the correct region is set in the top-right dropdown.

3. Right-click on your instance and select "Image">"Create Image" in the menu to create a new AMI. Once this is done, right-click on your instance again and select "Instance State">"Terminate" to terminate the instance.

4. Navigate to the [list of AMIs](https://console.aws.amazon.com/ec2/v2/home#Images). Take note of the id of your AMI, it should look similar to `ami-01232fd13c4ab62d7`. Wait for the AMI to become available.

5. Edit `terraform.tfvars` and set the value of `custom_ami` with the id of your AMI.

Your custom AMI will now be used next time the instance is booted with terraform!

An AMI is a snapshot of the content of a volume at some point in time. When the instance is terminated, the volume is still destroyed and all the data in the volume will be reverted to the state in the AMI the next time the instance is booted. For this reason, if some data that is desirable to be persisted is written to the volume, such as game update, create a new AMI and remove the old one. The next time the instance is booted, use the newly created AMI and the data will still be there.

## 6. Restart your instance after it was terminated
Just run `terraform apply` again when you want to boot up your machine again. If the AMI was correctly configured, your instance will show up in Parsec and there will be no need to log in with RDP.

## Appendix A: Uninstalling
To remove all the resources that were created by terraform, open a terminal/powershell in the folder where you unzipped the content of this repo and type in the following command:
``` bash
terraform destroy
```

The AMIs are not managed by terraform and need to be deleted manually in the AWS console. See the [documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/deregister-ami.html#clean-up-ebs-ami)
