# WinGet Update Detection Script for Intune
# Monitors specified apps and triggers remediation if updates needed

# MONITORED APPS - Edit this list as needed
$Apps = @(
    "Google.Chrome",
    "Mozilla.Firefox", 
    "Git.Git",
    "Notepad++.Notepad++",
    "7zip.7zip"
)

# Create log directory in ProgramData for better accessibility in system context
$LogDir = "$env:ProgramData\WinGet-AutoUpdate\Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

$LogFile = "$LogDir\WinGet-Detection.log"
$AllAppsLogFile = "$LogDir\WinGet-AllApps.log"
$UpgradeLogFile = "$LogDir\WinGet-Upgrade.log"
$AppsFile = "$LogDir\winget-apps.txt"

function Write-Log {
    param([string]$Msg, [string]$Level = "INFO")
    $Entry = "$(Get-Date -f 'HH:mm:ss') [$Level] $Msg"
    try {
        # Reset log if > 50KB to save space
        if ((Test-Path $LogFile) -and (Get-Item $LogFile).Length -gt 50KB) {
            Set-Content $LogFile "$(Get-Date -f 'HH:mm:ss') [INFO] Log reset" -Force
        }
        Add-Content $LogFile $Entry -Force
    } catch {}
    if ($Level -eq "ERROR") { Write-Error $Entry }
}

try {
    Write-Log "Detection started"
    Write-Log "Running as user: $env:USERNAME"
    Write-Log "Computer name: $env:COMPUTERNAME"
    
    # Find WinGet in common locations
    $WingetPath = $null
    $PossiblePaths = @(
        "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe",
        "${env:ProgramFiles}\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe",
        "${env:LOCALAPPDATA}\Microsoft\WindowsApps\winget.exe",
        "C:\Windows\System32\winget.exe"
    )

    foreach ($Path in $PossiblePaths) {
        $ExpandedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
        if ($ExpandedPath) {
            $WingetPath = $ExpandedPath[0].Path
            Write-Log "WinGet found at: $WingetPath"
            break
        }
    }

    # If still not found, try to find it using alternative method for system context
    if (-not $WingetPath) {
        $WinGetAppx = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -AllUsers
        if ($WinGetAppx) {
            $WingetPath = Join-Path $WinGetAppx.InstallLocation "winget.exe"
            Write-Log "WinGet found via AppX at: $WingetPath"
        }
    }
    
    if (-not $WingetPath -or -not (Test-Path $WingetPath)) {
        Write-Log "WinGet not available. Path attempted: $WingetPath" "ERROR"
        Write-Output "WinGet not found"
        exit 0
    }
      # Create apps list for remediation script
    $Apps | Out-File $AppsFile -Encoding UTF8 -Force
    Write-Log "Apps list created: $($Apps.Count) apps"
      # First, let's log all installed apps to help with diagnostics
    Write-Log "Getting list of all installed apps"
    try {
        $allAppsOutput = & $WingetPath list --accept-source-agreements 2>&1
        # Save list to ProgramData for easier access
        $allAppsOutput | Out-File $AllAppsLogFile -Force
        Write-Log "Successfully retrieved list of all installed apps"
    }
    catch {
        Write-Log "Error retrieving all apps: $_" "ERROR"
    }

    # Now check if our monitored apps exist in the current context    Write-Log "Checking if monitored apps exist in current context"
    $existingApps = @()
    foreach ($app in $Apps) {
        $appCheck = & $WingetPath list --id $app --accept-source-agreements 2>&1
        if ($appCheck -match [regex]::Escape($app)) {
            $existingApps += $app
            Write-Log "App found in current context: $app"
        }
        else {
            Write-Log "App NOT found in current context: $app" "WARNING"
        }}
    Write-Log "Found $($existingApps.Count) of $($Apps.Count) monitored apps in current context"

    # Check for updates using full path
    Write-Log "Checking for updates"
    $upgradeOutput = & $WingetPath upgrade --accept-source-agreements 2>&1
    # Save full upgrade output for diagnosis
    $upgradeOutput | Out-File $UpgradeLogFile -Force
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "WinGet upgrade check failed: $LASTEXITCODE" "ERROR"
        Write-Output "Update check failed"        exit 0
    }

    # Find apps needing updates
    $updatesNeeded = @()
    foreach ($app in $existingApps) {  # Only check apps that exist in this context
        if ($upgradeOutput | Select-String "^$([regex]::Escape($app))" -Quiet) {
            $updatesNeeded += $app
            Write-Log "Update needed: $app"
        }
        else {
            Write-Log "No update needed: $app"
        }
    }
    
    # Also check the full app list to have complete diagnostics
    foreach ($app in $Apps) {
        if ($existingApps -notcontains $app -and ($upgradeOutput | Select-String "^$([regex]::Escape($app))" -Quiet)) {
            Write-Log "NOTE: Update available for $app but app not found in current context" "WARNING"
        }
    }
    
    if ($updatesNeeded.Count -gt 0) {
        $updatesList = $updatesNeeded -join ", "
        Write-Log "Updates needed: $updatesList"
        Write-Output "Updates needed: $($updatesNeeded.Count) apps"
        exit 1  # Trigger remediation
    } else {
        if ($existingApps.Count -eq 0) {
            Write-Log "WARNING: No monitored apps found in system context" "WARNING"
            Write-Output "No monitored apps found in system context"
        } else {
            Write-Log "All apps up to date"
            Write-Output "All apps current"
        }
        exit 0  # No remediation needed
    }
    
} catch {
    Write-Log "Error: $($_.Exception.Message)" "ERROR"
    Write-Output "Detection error"
    exit 0
}
