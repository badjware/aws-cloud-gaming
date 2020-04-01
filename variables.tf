variable "aws_region" {
  description = "The aws region. Choose the one closest to you: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions"
  default="us-east-1"
}

variable "aws_instance_type" {
  description = "The aws instance type, Choose one with a GPU that fits your need: https://aws.amazon.com/ec2/instance-types/#Accelerated_Computing"
  default = "t2.micro"
}
