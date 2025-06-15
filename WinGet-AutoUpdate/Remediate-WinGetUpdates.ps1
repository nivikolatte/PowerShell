<#
.SYNOPSIS
    WinGet Update Remediation Script for Microsoft Intune

.DESCRIPTION
    This script performs automatic updates for applications managed via WinGet.
    It's designed to run as an Intune remediation script in SYSTEM context and processes
    the app list created by the corresponding detection script.

.PARAMETER None
    This script does not accept parameters. It reads the list of apps to update from
    the file created by the detection script.

.OUTPUTS
    Exit Code 0: All updates completed successfully
    Exit Code 1: One or more updates failed
    
    Console Output:
    - "Complete: X OK, Y failed" - Summary of update results
    - "No apps found to update in system context" - When no monitored apps are installed
    - Error messages for various failure scenarios

.NOTES
    File Name      : Remediate-WinGetUpdates.ps1
    Author         : IT Administration
    Prerequisite   : WinGet (Microsoft.DesktopAppInstaller) must be installed on target devices
    
    Version History:
    - v1.0: Initial version for Intune remediation
    
    Requirements:
    - PowerShell 5.1 or later
    - WinGet installed and accessible in SYSTEM context
    - Administrator privileges (provided by Intune SYSTEM context)
    - Apps list file created by detection script
    
    Logging:
    - All activities logged to: C:\ProgramData\WinGet-AutoUpdate\Logs\
    - Remediation log: WinGet-Remediation.log
    - Reads apps list from: winget-apps.txt
    
    Update Process:
    1. Locates WinGet executable in SYSTEM context
    2. Reads the apps list from detection script output
    3. Verifies which apps exist in current context
    4. Updates WinGet sources
    5. Performs silent updates with automatic agreements
    6. Reports success/failure status

.EXAMPLE
    # Manual execution for testing
    powershell.exe -ExecutionPolicy Bypass -File "Remediate-WinGetUpdates.ps1"
    
    # Intune deployment
    Deploy as remediation script in Intune remediation configuration

.LINK
    Microsoft Intune Documentation: https://docs.microsoft.com/en-us/mem/intune/
    WinGet Documentation: https://docs.microsoft.com/en-us/windows/package-manager/
#>

# WinGet Update Remediation Script for Intune
# Updates apps from the list created by detection script

# LOGGING CONFIGURATION
# Establish centralized logging in ProgramData for system-wide accessibility
# Ensures logs persist and are accessible regardless of execution context
$LogDir = "$env:ProgramData\WinGet-AutoUpdate\Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

$LogFile = "$LogDir\WinGet-Remediation.log"
$AppsFile = "$LogDir\winget-apps.txt"

function Write-Log {
    <#
    .SYNOPSIS
        Writes log entries to the remediation log file
    
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

function Update-App {
    <#
    .SYNOPSIS
        Updates a single application using WinGet
    
    .DESCRIPTION
        Performs a silent update of the specified application and handles
        common WinGet exit codes to determine success or failure
    
    .PARAMETER AppId
        The WinGet package ID of the application to update
    
    .OUTPUTS
        Returns $true if update was successful, $false otherwise
    #>
    param([string]$AppId)
    
    Write-Log "Updating: $AppId"
    
    # Execute WinGet upgrade with silent installation and automatic agreement acceptance
    # These parameters ensure non-interactive operation suitable for SYSTEM context
    & $WingetPath upgrade --id $AppId --silent --accept-package-agreements --accept-source-agreements | Out-Null
    
    # WINGET EXIT CODE INTERPRETATION
    # Handle common WinGet return codes to provide accurate update status
    switch ($LASTEXITCODE) {
        0 { 
            Write-Log "Success: $AppId"
            return $true 
        }
        -1978335189 { 
            Write-Log "No update needed: $AppId"
            return $true 
        }
        -1978335212 { 
            Write-Log "Already current: $AppId"
            return $true 
        }
        default { 
            Write-Log "Failed: $AppId (Code: $LASTEXITCODE)" "ERROR"
            return $false 
        }
    }
}

try {
    Write-Log "Remediation started"
    Write-Log "Running as user: $env:USERNAME"
    Write-Log "Computer name: $env:COMPUTERNAME"
    
    # WINGET DISCOVERY SECTION
    # Locate WinGet executable in SYSTEM context - critical for remediation success
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

    # Alternative discovery method using AppX package enumeration
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
        exit 1
    }
    
    # PRIVILEGE VALIDATION
    # Verify execution context - log warning if not running with elevated privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$isAdmin) {
        Write-Log "Not running as admin - some updates may fail" "WARNING"
    }
    
    # APPS LIST VALIDATION
    # Ensure detection script has provided the list of apps to update
    if (!(Test-Path $AppsFile)) {
        Write-Log "Apps list not found" "ERROR"
        Write-Output "No apps to update"
        exit 0
    }

    $apps = Get-Content $AppsFile | Where-Object { $_.Trim() }
    Write-Log "Processing $($apps.Count) apps from list"
    
    # CONTEXT VERIFICATION SECTION
    # Validate which apps are actually available in current execution context
    # This prevents attempting updates on apps not visible to SYSTEM account
    $existingApps = @()
    foreach ($app in $apps) {
        $appCheck = & $WingetPath list --id $app --accept-source-agreements 2>&1
        if ($appCheck -match [regex]::Escape($app)) {
            $existingApps += $app
            Write-Log "App found in current context: $app"
        }
        else {
            Write-Log "App NOT found in current context: $app" "WARNING"
        }
    }
    
    Write-Log "Found $($existingApps.Count) of $($apps.Count) apps in current context"
    
    if ($existingApps.Count -eq 0) {
        Write-Log "No monitored apps found in system context" "WARNING"
        Write-Output "No apps found to update in system context"
        exit 0
    }
    
    # SOURCE UPDATE SECTION
    # Refresh WinGet package sources to ensure latest package information
    & $WingetPath source update --accept-source-agreements | Out-Null

    # UPDATE EXECUTION SECTION
    # Process each app update with error handling and result tracking
    $success = 0
    $failed = 0
    
    foreach ($app in $existingApps) {  # Only update apps that exist in this context
        if (Update-App $app) {
            $success++
        } else {
            $failed++
        }
    }

    # RESULTS REPORTING SECTION
    # Generate summary and determine exit code for Intune reporting
    $summary = "Complete: $success OK, $failed failed"
    Write-Log $summary
    Write-Output $summary
    
    if ($failed -gt 0) {
        exit 1
    } else {
        exit 0
    }
    
} catch {
    Write-Log "Error: $($_.Exception.Message)" "ERROR"
    Write-Output "Remediation error"
    exit 1
}
