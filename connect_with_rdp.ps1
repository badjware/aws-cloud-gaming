#!/usr/bin/env pwsh

$ip = (terraform output instance_ip) | Out-String
$user = (terraform output instance_user) | Out-String
$password = (terraform output instance_password) | Out-String
$encrytedPassword = ($password | ConvertTo-SecureString -AsPlainText -Force) | ConvertFrom-SecureString

@"
full address:s:$ip
username:s:$user
password 51:b:$encrytedPassword
"@ | Out-File -FilePath "aws-cloud-gaming.rdp"
Invoke-Item "aws-cloud-gaming.rdp"
Remove-Item "aws-cloud-gaming.rdp"

