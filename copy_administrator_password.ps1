#!/usr/bin/env pwsh

$password = (terraform output instance_password) | Out-String
Set-Clipboard -Value "$password"
