# WinGet Update Remediation Script for Intune
# Updates apps from the list created by detection script

# Create log directory in ProgramData for better accessibility in system context
$LogDir = "$env:ProgramData\WinGet-AutoUpdate\Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

$LogFile = "$LogDir\WinGet-Remediation.log"
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

function Update-App {
    param([string]$AppId)
    
    Write-Log "Updating: $AppId"
    & $WingetPath upgrade --id $AppId --silent --accept-package-agreements --accept-source-agreements | Out-Null
    
    # Handle common WinGet exit codes
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
        exit 1
    }
    
    # Check if running as admin
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$isAdmin) {
        Write-Log "Not running as admin - some updates may fail" "WARNING"
    }
    
    # Load apps list
    if (!(Test-Path $AppsFile)) {
        Write-Log "Apps list not found" "ERROR"
        Write-Output "No apps to update"        exit 0
    }

    $apps = Get-Content $AppsFile | Where-Object { $_.Trim() }
    Write-Log "Processing $($apps.Count) apps from list"
      # First check which apps exist in this context
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
      # Update WinGet sources
    & $WingetPath source update --accept-source-agreements | Out-Null

    # Update each app
    $success = 0
    $failed = 0
    
    foreach ($app in $existingApps) {  # Only update apps that exist in this context
        if (Update-App $app) {
            $success++
        } else {
            $failed++
        }    }

    # Report results
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
