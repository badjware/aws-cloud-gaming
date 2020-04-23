<powershell>

function install-chocolatey {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    choco feature enable -n allowGlobalConfirmation
}

function install-awstools {
    choco install awstools.powershell
}

function install-steam {
    choco install steam
}

function install-parsec-cloud-preparation-tool {
    # https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool

    if (!(Test-Path -Path "C:\Parsec-Cloud-Preparation-Tool")) {
        [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
        (New-Object System.Net.WebClient).DownloadFile("https://github.com/badjware/Parsec-Cloud-Preparation-Tool/archive/master.zip","C:\Parsec-Cloud-Preparation-Tool.zip")
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
}

function install-admin-password {
    $password = (Get-SSMParameter -WithDecryption $true -Name '${password_ssm_parameter}').Value
    net user Administrator "$password"
}

function install-autologin {
    $password = (Get-SSMParameter -WithDecryption $true -Name '${password_ssm_parameter}').Value
    $regPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    [microsoft.win32.registry]::SetValue($regPath, "AutoAdminLogon", "1")
    [microsoft.win32.registry]::SetValue($regPath, "DefaultUserName", "Administrator")
    [microsoft.win32.registry]::SetValue($regPath, "DefaultPassword", $password)
}

function install-graphic-driver {
    # https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/install-nvidia-driver.html#nvidia-gaming-driver

    if (!(Test-Path -Path "C:\Program Files\NVIDIA Corporation\NVSMI")) {
        # download from s3 and extract
        $Bucket = "nvidia-gaming"
        $KeyPrefix = "windows/latest"
        $Objects = Get-S3Object -BucketName $Bucket -KeyPrefix $KeyPrefix -Region us-east-1
        $LocalDownloadFile = "C:\nvidia-driver\driver.zip"
        $ExtractionPath = "C:\nvidia-driver\driver"
        foreach ($Object in $Objects) {
            if ($Object.Size -ne 0) {
                Copy-S3Object -BucketName $Bucket -Key $Object.Key -LocalFile $LocalDownloadFile -Region us-east-1
                Expand-Archive $LocalDownloadFile -DestinationPath $ExtractionPath
                break
            }
        }
    
        # install driver
        $InstallerFile = Get-ChildItem -path $ExtractionPath -Include "*win10*" -Recurse | ForEach-Object { $_.FullName }
        Start-Process -FilePath $InstallerFile -ArgumentList "/s /n" -Wait
     
        # install licence
        Copy-S3Object -BucketName $Bucket -Key "GridSwCert-Windows.cert" -LocalFile "C:\Users\Public\Documents\GridSwCert.txt" -Region us-east-1
        [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global", "vGamingMarketplace", 0x02)
    

        # install task to disable second monitor on login
        $trigger = New-ScheduledTaskTrigger -AtLogon
        $action = New-ScheduledTaskAction -Execute displayswitch.exe -Argument "/internal"
        Register-ScheduledTask -TaskName "disable-second-monitor" -Trigger $trigger -Action $action -RunLevel Highest

        # cleanup
       Remove-Item -Path "C:\nvidia-driver" -Recurse
    }
}

install-chocolatey
install-awstools
install-parsec-cloud-preparation-tool
install-admin-password
install-autologin
install-steam
install-graphic-driver
</powershell>
