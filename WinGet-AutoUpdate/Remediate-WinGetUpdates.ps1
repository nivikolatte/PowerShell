# WinGet Update Remediation Script for Intune
# Updates apps from the list created by detection script

$LogFile = "$env:TEMP\WinGet-Remediation.log"
$AppsFile = "$env:TEMP\winget-apps.txt"

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
    winget upgrade --id $AppId --silent --accept-package-agreements --accept-source-agreements | Out-Null
    
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
    
    # Check WinGet availability
    if (!(Get-Command winget -EA SilentlyContinue)) {
        Write-Log "WinGet not available" "ERROR"
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
        Write-Output "No apps to update"
        exit 0
    }
    
    $apps = Get-Content $AppsFile | Where-Object { $_.Trim() }
    Write-Log "Processing $($apps.Count) apps"
    
    # Update WinGet sources
    winget source update --accept-source-agreements | Out-Null
    
    # Update each app
    $success = 0
    $failed = 0
    
    foreach ($app in $apps) {
        if (Update-App $app) {
            $success++
        } else {
            $failed++
        }
    }
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
