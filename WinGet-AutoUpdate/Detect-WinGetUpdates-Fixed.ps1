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

$LogFile = "$env:TEMP\WinGet-Detection.log"
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

try {
    Write-Log "Detection started"
    
    # Check WinGet availability
    if (!(Get-Command winget -EA SilentlyContinue)) {
        Write-Log "WinGet not available" "ERROR"
        Write-Output "WinGet not found"
        exit 0
    }
    
    # Create apps list for remediation script
    $Apps | Out-File $AppsFile -Encoding UTF8 -Force
    Write-Log "Apps list created: $($Apps.Count) apps"
    
    # Check for updates
    $upgradeOutput = winget upgrade --accept-source-agreements 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "WinGet upgrade check failed: $LASTEXITCODE" "ERROR"
        Write-Output "Update check failed"
        exit 0
    }
    
    # Find apps needing updates
    $updatesNeeded = @()
    foreach ($app in $Apps) {
        if ($upgradeOutput | Select-String "^$([regex]::Escape($app))" -Quiet) {
            $updatesNeeded += $app
        }
    }
    
    if ($updatesNeeded.Count -gt 0) {
        $updatesList = $updatesNeeded -join ", "
        Write-Log "Updates needed: $updatesList"
        Write-Output "Updates needed: $($updatesNeeded.Count) apps"
        exit 1  # Trigger remediation
    } else {
        Write-Log "All apps up to date"
        Write-Output "All apps current"
        exit 0  # No remediation needed
    }
    
} catch {
    Write-Log "Error: $($_.Exception.Message)" "ERROR"
    Write-Output "Detection error"
    exit 0
}
