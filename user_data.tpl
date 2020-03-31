<powershell>
# Setup chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

# Install AWS Tools for PowerShell
choco install awstools.powershell

# Setup the administator password
$password = (Get-SSMParameter -WithDecryption $true -Name '${password_parameter_name}').Value
net user Administrator "$password"

</powershell>
