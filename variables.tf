variable "region" {
  description = "The aws region. Choose the one closest to you: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions"
  type = string
}

variable "allowed_availability_zone_identifier" {
  description = "The allowed availability zone identify (the letter suffixing the region). Choose ones that allows you to request the desired instance as spot instance in your region. An availability zone will be selected at random and the instance will be booted in it."
  type = list
  default = ["a", "b"]
}

variable "instance_type" {
  description = "The aws instance type, Choose one with a GPU that fits your need: https://aws.amazon.com/ec2/instance-types/#Accelerated_Computing"
  type = string
  default = "g4dn.xlarge"
}

variable "root_block_device_size_gb" {
  description = "The size of the root block device (C:\\ drive) attached to the instance"
  type = number
  default = 120
}

variable "custom_ami" {
  description = "Use the specified ami instead of the most recent windows ami in available in the region"
  type = string
  default = ""
}
