#!/usr/bin/env pwsh

New-Item -ItemType Directory -Force -Path "$HOME/.aws" >$null

if (Test-Path -Path "$HOME/.aws/credentials") {
    
    $input = Read-Host "AWS credentials already set! Replace it? [y/N] "
    if (!($input -eq "y" -or $input -eq "Y")) {
        exit
    }
}

$aws_access_key_id  = ""
$aws_secret_access_key = ""
while ($aws_access_key_id -eq "") {
    $aws_access_key_id = Read-Host "Access Key Id    "
}
while ($aws_secret_access_key -eq "") {
    $aws_secret_access_key = Read-Host "Secret Access Key"
}
@"
[default]
aws_access_key_id = $aws_access_key_id
aws_secret_access_key = $aws_secret_access_key
"@ | Out-File -Encoding ASCII -FilePath "$HOME/.aws/credentials"

Write-Output "AWS credentials configured"
