# Security policies to check
$settingsFile = "C:\Users\User\Desktop\CP_Scoring_Engine\Configs\settings.json"
$settingsJSON = Get-Content $settingsFile -Raw | ConvertFrom-Json
$GLOBAL:POLICY_CONFIG = @{
    "MinimumPasswordLength"=0
}

Import-Module NetSecurity

$running = $true

# Add softwares to check
$softwareList = New-Object -TypeName 'System.Collections.ArrayList';
$softwareList.Add("C:\Program Files (x86)\MonkeyDanPasswords.txt")
$softwareList.Add("C:\Program Files (x86)\Microsoft\Skype for Desktop")

$forensicsList = New-Object -TypeName 'System.Collections.ArrayList';
$forensicsList.Add("C:\Users\User\Desktop\ForensicsQuestionOne.txt")
$forensicsList.Add("C:\Users\User\Desktop\ForensicsQuestionTwo.txt")

# Add users to check
$user_names = New-Object -TypeName 'System.Collections.ArrayList';
$user_names.Add("BenjaminTheHacker")

function policyCheck {
    $secedit = secedit /export /areas SECURITYPOLICY /cfg $env:temp\secpol.cfg
    $policy = Get-Content $env:temp\secpol.cfg | Select-String "MinimumPasswordLength" | ForEach-Object { $_.ToString() -replace '\s+', '' }
    $minPasswordLength = $policy -replace "MinimumPasswordLength=", ""
    Remove-Item $env:temp\secpol.cfg
    if ($minPasswordLength -gt 10 -and $GLOBAL:POLICY_CONFIG["MinimumPasswordLength"] -eq 0) {
        pointNotification -header "Points have been updated!" -text "Password policy secured."
        $GLOBAL:POLICY_CONFIG["MinimumPasswordLength"] = 1
        $GLOBAL:PROGRESS.Add("Minimum password length policy has updated!", 1)
    }
}
function softwareCheck {
    Param (
        [System.Collections.ArrayList] $folders
    )
    for ($i = 0; $i -lt $folders.Count; $i++) {
        $folder = $folders[$i]
        if (Test-Path -Path $folder) {
            # File still exists
        } else {
            $file_name = Split-Path $folder -Leaf
            $GLOBAL:PROGRESS.Add("$file_name deleted", 1)
            $folders.Remove($folder)
            pointNotification -header "Points have been updated!" -text "$file_name has been deleted."
        }
    }
}

function firewallCheck {
    $profiles = Get-NetFirewallProfile
    $firewallEnabled = $false
    foreach ($profile in $profiles) {
        if ($profile.Enabled) {
            $firewallEnabled = $true
            break
        }
    }
    if ($firewallEnabled -and !($GLOBAL:PROGRESS.ContainsKey("Firewall enabled"))) {
        pointNotification -header "Points have been updated!" -text "Firewall enabled."
        $GLOBAL:PROGRESS.Add("Firewall enabled", 1)
    }
}

function pointNotification {
    Param (
        [string] $header,
        [string] $text
    )
    New-BurntToastNotification -AppLogo $settingsJSON.logo -Text 'CP Scoring Engine', $header, $text
}

function checkDeletedUsers {
    Param (
        [System.Collections.ArrayList] $usernames
    )
    for ($i = 0; $i -lt $usernames.Count; $i++) {
        $user = $usernames[$i]
        $exists = Get-LocalUser -Name $user -ErrorAction SilentlyContinue
        if ($exists) {
            
        } else {
            pointNotification -header "Points have been updated!" -text "Bad user: $user has been removed."
            $GLOBAL:PROGRESS.Add("$user has been removed", 1)
            $usernames.Remove($user)
        }
    }
}

function checkForensics {
    $ForensicsOne = "C:\Users\User\Desktop\ForensicsQuestionOne.txt"
    $ForensicsTwo = "C:\Users\User\Desktop\ForensicsQuestionTwo.txt"
    foreach ($line in Get-Content -Path $ForensicsOne) {
        if ($line -eq "abcdefg02946$!" -and !($GLOBAL:PROGRESS.ContainsKey("Forensics Question 1 Completed"))) {
            pointNotification -header "Points have been updated!" -text "Forensics Question 1 Completed."
            $GLOBAL:PROGRESS.Add("Forensics Question 1 Completed", 1)
        }
    }
    foreach ($line in Get-Content -Path $ForensicsTwo) {
        if ($line -eq "Browsers" -and !($GLOBAL:PROGRESS.ContainsKey("Forensics Question 2 Completed"))) {
            pointNotification -header "Points have been updated!" -text "Forensics Question 2 Completed."
            $GLOBAL:PROGRESS.Add("Forensics Question 2 Completed", 1)
        }
    }
}

function cleanupImage {
    # Change back local security policies to previous version.
    secedit /configure /db C:\Windows\security\local.sdb /cfg $settingsJSON.default_config_path /areas SECURITYPOLICY
    # Remove chrome window for scoring engine.
    $chromeProcess = Get-Process -Name chrome
    $chromeProcess | ForEach-Object { Stop-Process $_.Id }
    # Delete all softwares that were being checked.
    for ($i = 0; $i -lt $softwareList.Count; $i++) {
        $folder = $softwareList[$i]
        if (Test-Path -Path $folder) {
            Remove-Item -Path $folder
        }
    }
    # Delete all forensics question txt files.
    for ($i = 0; $i -lt $forensicsList.Count; $i++) {
        $folder = $forensicsList[$i]
        if (Test-Path -Path $folder) {
            Remove-Item -Path $folder
        }
    }
    # Delete all extra users that were created.
    for ($i = 0; $i -lt $user_names.Count; $i++) {
        $user = $user_names[$i]
        if (Get-LocalUser -Name $user -ErrorAction SilentlyContinue) {
            Remove-LocalUser -Name $user -Confirm:$false
        }
    }
    # Fix firewall
    Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True
    Write-Host "Image has been cleaned up."
    Exit
}
function checkResetFlag {
    if (Test-Path -Path $settingsJSON.resetFlagFilePath) {
        Remove-Item -Path $settingsJSON.resetFlagFilePath -Force
        cleanupImage
    }
}

$GLOBAL:PROGRESS = @{}
$json = $GLOBAL:PROGRESS | ConvertTo-Json
$json | Out-File -FilePath $settingsJSON.hashtable_path
while ($running) {
    start-sleep -seconds 5;
    softwareCheck -folders $softwareList
    policyCheck
    firewallCheck
    checkForensics
    checkDeletedUsers -usernames $user_names
    $json = $GLOBAL:PROGRESS | ConvertTo-Json
    $json | Out-File -FilePath $settingsJSON.hashtable_path
    checkResetFlag
}
