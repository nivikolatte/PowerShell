<#
.SYNOPSIS
    WinGet Update Detection Script for Microsoft Intune Remediation

.DESCRIPTION
    This script monitors specified applications installed via WinGet and detects if updates are available.
    It's designed to run as an Intune detection script in SYSTEM context and triggers remediation
    when updates are needed.

.PARAMETER None
    This script does not accept parameters. Edit the $Apps array within the script to modify
    the list of monitored applications.

.OUTPUTS
    Exit Code 0: All monitored apps are up to date (no remediation needed)
    Exit Code 1: Updates are available for one or more apps (triggers remediation)
    
    Console Output:
    - "All apps current" - When no updates needed
    - "Updates needed: X apps" - When updates are available
    - "No monitored apps found in system context" - When no apps from the list are installed
    - Error messages for various failure scenarios

.NOTES
    File Name      : Detect-WinGetUpdates-Fixed.ps1
    Author         : IT Administration
    Prerequisite   : WinGet (Microsoft.DesktopAppInstaller) must be installed on target devices
    
    Version History:
    - v1.0: Initial version for Intune remediation
    
    Requirements:
    - PowerShell 5.1 or later
    - WinGet installed and accessible in SYSTEM context
    - Administrator privileges (provided by Intune SYSTEM context)
    
    Logging:
    - All activities logged to: C:\ProgramData\WinGet-AutoUpdate\Logs\
    - Detection log: WinGet-Detection.log
    - All apps inventory: WinGet-AllApps.log
    - Upgrade check output: WinGet-Upgrade.log
    - Apps list for remediation: winget-apps.txt

.EXAMPLE
    # Manual execution for testing
    powershell.exe -ExecutionPolicy Bypass -File "Detect-WinGetUpdates-Fixed.ps1"
    
    # Intune deployment
    Deploy as detection script in Intune remediation configuration

.LINK
    Microsoft Intune Documentation: https://docs.microsoft.com/en-us/mem/intune/
    WinGet Documentation: https://docs.microsoft.com/en-us/windows/package-manager/
#>

# MONITORED APPS CONFIGURATION
# Edit this array to customize which applications are monitored for updates
# Use exact WinGet package IDs - verify with: winget search <appname>
$Apps = @(    "Google.Chrome",        # Google Chrome browser
    "Mozilla.Firefox",      # Mozilla Firefox browser
    "Git.Git",             # Git version control system
    "Notepad++.Notepad++", # Notepad++ text editor
    "7zip.7zip"            # 7-Zip file archiver
)

# LOGGING CONFIGURATION
# Create centralized logging directory in ProgramData for system-wide accessibility
# This ensures logs are available regardless of execution context (SYSTEM/USER)
$LogDir = "$env:ProgramData\WinGet-AutoUpdate\Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

$LogFile = "$LogDir\WinGet-Detection.log"
$AllAppsLogFile = "$LogDir\WinGet-AllApps.log"
$UpgradeLogFile = "$LogDir\WinGet-Upgrade.log"
$AppsFile = "$LogDir\winget-apps.txt"

function Write-Log {
    <#
    .SYNOPSIS
        Writes log entries to the detection log file
    
    .DESCRIPTION
        Creates timestamped log entries with severity levels and handles log rotation
        to prevent excessive file growth
    
    .PARAMETER Msg
        The message to log
    
    .PARAMETER Level
        The severity level (INFO, WARNING, ERROR). Default is INFO
    #>
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
    
    # WINGET DISCOVERY SECTION
    # Find WinGet executable in common system and user locations
    # This is critical for SYSTEM context where paths may differ
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

    # Alternative discovery method for SYSTEM context using AppX packages
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
    
    # APPS LIST PREPARATION
    # Create apps list file for remediation script consumption
    $Apps | Out-File $AppsFile -Encoding UTF8 -Force
    Write-Log "Apps list created: $($Apps.Count) apps"
    
    # DIAGNOSTIC LOGGING SECTION
    # Generate comprehensive app inventory for troubleshooting
    Write-Log "Getting list of all installed apps"
    try {
        $allAppsOutput = & $WingetPath list --accept-source-agreements 2>&1
        # Save complete inventory to ProgramData for system-wide access
        $allAppsOutput | Out-File $AllAppsLogFile -Force
        Write-Log "Successfully retrieved list of all installed apps"
    }
    catch {
        Write-Log "Error retrieving all apps: $_" "ERROR"
    }

    # CONTEXT VALIDATION SECTION
    # Verify which monitored apps actually exist in current execution context
    # This is crucial for SYSTEM vs USER context differences
    Write-Log "Checking if monitored apps exist in current context"
    $existingApps = @()
    foreach ($app in $Apps) {
        $appCheck = & $WingetPath list --id $app --accept-source-agreements 2>&1
        if ($appCheck -match [regex]::Escape($app)) {
            $existingApps += $app
            Write-Log "App found in current context: $app"
        }
        else {
            Write-Log "App NOT found in current context: $app" "WARNING"
        }
    }
    Write-Log "Found $($existingApps.Count) of $($Apps.Count) monitored apps in current context"

    # UPDATE DETECTION SECTION
    # Check for available updates using WinGet upgrade command
    Write-Log "Checking for updates"
    $upgradeOutput = & $WingetPath upgrade --accept-source-agreements 2>&1
    # Preserve complete upgrade output for detailed analysis
    $upgradeOutput | Out-File $UpgradeLogFile -Force
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "WinGet upgrade check failed: $LASTEXITCODE" "ERROR"
        Write-Output "Update check failed"
        exit 0
    }

    # UPDATE ANALYSIS SECTION
    # Parse upgrade output to identify apps needing updates
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
    
    # Additional diagnostic logging for comprehensive monitoring
    foreach ($app in $Apps) {
        if ($existingApps -notcontains $app -and ($upgradeOutput | Select-String "^$([regex]::Escape($app))" -Quiet)) {
            Write-Log "NOTE: Update available for $app but app not found in current context" "WARNING"
        }
    }
    
    # REMEDIATION DECISION LOGIC
    # Determine if remediation should be triggered based on findings
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
