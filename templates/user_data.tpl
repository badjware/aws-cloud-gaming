<powershell>
# Setup chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

# Setup the administator password
choco install awstools.powershell
$password = (Get-SSMParameter -WithDecryption $true -Name '${password_ssm_parameter}').Value
net user Administrator "$password"

if (!(Test-Path -Path C:\Parsec-Cloud-Preparation-Tool)) {
    # Download Parsec-Cloud-Preparation-Tool
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    (New-Object System.Net.WebClient).DownloadFile("https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool/archive/master.zip","C:\Parsec-Cloud-Preparation-Tool.zip")
    New-Item -Path "C:\Parsec-Cloud-Preparation-Tool" -ItemType Directory
    Expand-Archive "C:\Parsec-Cloud-Preparation-Tool.zip" -DestinationPath "C:\Parsec-Cloud-Preparation-Tool"
    Remove-Item -Path "C:\Parsec-Cloud-Preparation-Tool.zip"

    # Setup scheduled task to run Parsec-Cloud-Preparation-Tool once at logon
    $trigger = New-ScheduledTaskTrigger -AtLogon
    $action = New-ScheduledTaskAction -Execute powershell.exe -WorkingDirectory "C:\Parsec-Cloud-Preparation-Tool\Parsec-Cloud-Preparation-Tool-master" -Argument "C:\Parsec-Cloud-Preparation-Tool\Parsec-Cloud-Preparation-Tool-master\Loader.ps1"
    $selfDestruct = New-ScheduledTaskAction -Execute powershell.exe -Argument "-Command `"Disable-ScheduledTask -TaskName Parsec-Cloud-Preparation-Tool`""
    Register-ScheduledTask -TaskName Parsec-Cloud-Preparation-Tool -Trigger $trigger -Action $action,$selfDestruct -RunLevel Highest
}
</powershell>
