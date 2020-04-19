<powershell>

# Setup chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

choco install awstools.powershell

if (!(Test-Path -Path C:\Parsec-Cloud-Preparation-Tool)) {
    # Download Parsec-Cloud-Preparation-Tool
    # https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    (New-Object System.Net.WebClient).DownloadFile("https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool/archive/master.zip","C:\Parsec-Cloud-Preparation-Tool.zip")
    New-Item -Path "C:\Parsec-Cloud-Preparation-Tool" -ItemType Directory
    Expand-Archive "C:\Parsec-Cloud-Preparation-Tool.zip" -DestinationPath "C:\Parsec-Cloud-Preparation-Tool"
    Remove-Item -Path "C:\Parsec-Cloud-Preparation-Tool.zip"

    # Setup scheduled task to run Parsec-Cloud-Preparation-Tool once at logon
    $taskname = "Parsec-Cloud-Preparation-Tool"
    $trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay $(New-TimeSpan -seconds 30)
    $trigger.Delay = "PT30S"
    $action = New-ScheduledTaskAction -Execute powershell.exe -WorkingDirectory "C:\Parsec-Cloud-Preparation-Tool\Parsec-Cloud-Preparation-Tool-master" -Argument "C:\Parsec-Cloud-Preparation-Tool\Parsec-Cloud-Preparation-Tool-master\Loader.ps1"
    $selfDestruct = New-ScheduledTaskAction -Execute powershell.exe -Argument "-Command `"Disable-ScheduledTask -TaskName $taskname`""
    Register-ScheduledTask -TaskName $taskname -Trigger $trigger -Action $action,$selfDestruct -RunLevel Highest
}

# Setup the administator password
$password = (Get-SSMParameter -WithDecryption $true -Name '${password_ssm_parameter}').Value
net user Administrator "$password"

# Download the NVIDIA gaming driver
# https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/install-nvidia-driver.html#nvidia-gaming-driver
$Bucket = "nvidia-gaming"
# FIXME: latest is bugged right now
# https://forums.aws.amazon.com/thread.jspa?messageID=939425#939425
#$KeyPrefix = "windows/latest"
$KeyPrefix = "windows/GRID-442.19"
$LocalPath = "$home\Desktop\NVIDIA"
$Objects = Get-S3Object -BucketName $Bucket -KeyPrefix $KeyPrefix -Region us-east-1
foreach ($Object in $Objects) {
    $LocalFileName = $Object.Key
    if ($LocalFileName -ne '' -and $Object.Size -ne 0) {
        $LocalFilePath = Join-Path $LocalPath $LocalFileName
        Copy-S3Object -BucketName $Bucket -Key $Object.Key -LocalFile $LocalFilePath -Region us-east-1
    }
}
Copy-S3Object -BucketName $Bucket -Key "GridSwCert-Windows.cert" -LocalFile "C:\Users\Public\Documents\GridSwCert.txt" -Region us-east-1
[microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global", "vGamingMarketplace", 0x02)

# Setup steam
choco install steam

</powershell>
