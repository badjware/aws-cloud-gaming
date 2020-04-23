#!/usr/bin/env pwsh

$ip = (terraform output instance_ip) | Out-String
$user = "Administrator"

@"
full address:s:$ip
username:s:$user
"@ | Out-File -Encoding ASCII  -FilePath "aws-cloud-gaming.rdp"
Invoke-Item "aws-cloud-gaming.rdp"

