# Security policies to check
$settingsFile = "C:\Users\User\Desktop\CP_Scoring_Engine\settings.json"
$settingsJSON = Get-Content $settingsFile -Raw | ConvertFrom-Json
$GLOBAL:POLICY_CONFIG = @{
    "MinimumPasswordLength"=0
}

# Add softwares to check
$softwareList = New-Object -TypeName 'System.Collections.ArrayList';
$softwareList.Add("C:\Users\User\Desktop\MonkeyDanPasswords.txt")
$softwareList.Add("C:\Program Files (x86)\Microsoft\Skype for Desktop")

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

start-sleep -seconds 5;
$GLOBAL:PROGRESS = @{}
while ($true) {
    start-sleep -seconds 5;
    softwareCheck -folders $softwareList
    policyCheck
    checkDeletedUsers -usernames $user_names

    $json = $GLOBAL:PROGRESS | ConvertTo-Json
    $json | Out-File -FilePath $settingsJSON.hashtable_path
}
