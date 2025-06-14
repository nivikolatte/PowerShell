#Requires -Version 5.1
<#
.SYNOPSIS
    Downloads and sets up PowerShell App Deployment Toolkit 4.0

.DESCRIPTION
    This script automates the download and setup of PSADT 4.0 from the official GitHub repository.
    It ensures the toolkit is properly installed and ready for package generation.

.PARAMETER InstallPath
    Installation path for PSADT 4.0 (default: C:\PSADT4)

.PARAMETER ForceDownload
    Force re-download even if PSADT 4.0 is already installed

.PARAMETER Branch
    GitHub branch to download (default: main for latest stable)

.EXAMPLE
    .\Setup-PSADT4.ps1

.EXAMPLE
    .\Setup-PSADT4.ps1 -InstallPath "D:\Tools\PSADT4" -ForceDownload

.NOTES
    Author: IT Department
    Version: 1.0.0
    Date: 2025-06-14
    Requires: PowerShell 5.1+, Internet connection
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$InstallPath = "C:\PSADT4",
    
    [Parameter(Mandatory = $false)]
    [switch]$ForceDownload,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Branch = "main"
)

#region Helper Functions
function Write-LogMessage {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow" 
        Error = "Red"
        Success = "Green"
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Type]
}

function Test-PSADT4Installation {
    param([string]$Path)
    
    $requiredFiles = @(
        "Toolkit\Deploy-Application.ps1",
        "Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1",
        "Toolkit\AppDeployToolkit\AppDeployToolkitExtensions.ps1"
    )
    
    foreach ($file in $requiredFiles) {
        if (!(Test-Path (Join-Path $Path $file))) {
            return $false
        }
    }
    
    # Check for PSADT 4.0 version
    $mainScript = Join-Path $Path "Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1"
    $content = Get-Content $mainScript -Raw -ErrorAction SilentlyContinue
    
    if ($content -match "Version.*4\." -or $content -match "PSAppDeployToolkit.*4") {
        return $true
    }
    
    return $false
}

function Get-LatestPSADTRelease {
    try {
        Write-LogMessage "Checking for latest PSADT 4.0 release..." -Type "Info"
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/PSAppDeployToolkit/PSAppDeployToolkit/releases" -UseBasicParsing
        
        # Find the latest 4.x release
        $psadt4Release = $releases | Where-Object { $_.tag_name -match "^4\." -and -not $_.prerelease } | Select-Object -First 1
        
        if ($psadt4Release) {
            return $psadt4Release
        } else {
            # If no stable 4.x release, look for pre-release
            $psadt4Release = $releases | Where-Object { $_.tag_name -match "^4\." } | Select-Object -First 1
            return $psadt4Release
        }
    }
    catch {
        Write-LogMessage "Failed to get release information from GitHub: $($_.Exception.Message)" -Type "Warning"
        return $null
    }
}

function Download-PSADT4FromGitHub {
    param(
        [string]$InstallPath,
        [string]$Branch = "main"
    )
    
    try {
        # Try to get latest release first
        $release = Get-LatestPSADTRelease
        
        if ($release -and $release.assets) {
            # Download from release assets
            $asset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
            
            if ($asset) {
                Write-LogMessage "Downloading PSADT 4.0 release: $($release.tag_name)" -Type "Info"
                $downloadUrl = $asset.browser_download_url
                $zipPath = Join-Path $env:TEMP "PSADT4-$($release.tag_name).zip"
                
                Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
                
                # Extract ZIP
                Write-LogMessage "Extracting PSADT 4.0..." -Type "Info"
                $extractPath = Join-Path $env:TEMP "PSADT4-Extract"
                
                if (Test-Path $extractPath) {
                    Remove-Item $extractPath -Recurse -Force
                }
                
                Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
                
                # Find the toolkit folder and copy
                $toolkitPath = Get-ChildItem -Path $extractPath -Recurse -Directory | Where-Object { $_.Name -eq "Toolkit" } | Select-Object -First 1
                
                if ($toolkitPath) {
                    if (Test-Path $InstallPath) {
                        Remove-Item $InstallPath -Recurse -Force
                    }
                    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
                    
                    Copy-Item -Path $toolkitPath.Parent.FullName\* -Destination $InstallPath -Recurse -Force
                    
                    # Cleanup
                    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
                    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
                    
                    return $true
                }
            }
        }
        
        # Fallback: Download from main branch
        Write-LogMessage "Downloading PSADT 4.0 from main branch..." -Type "Info"
        $zipUrl = "https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/archive/refs/heads/$Branch.zip"
        $zipPath = Join-Path $env:TEMP "PSADT4-$Branch.zip"
        
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
        
        # Extract and setup
        $extractPath = Join-Path $env:TEMP "PSADT4-Extract"
        
        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }
        
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        # Find the extracted folder
        $extractedFolder = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
        
        if ($extractedFolder) {
            if (Test-Path $InstallPath) {
                Remove-Item $InstallPath -Recurse -Force
            }
            New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
            
            Copy-Item -Path $extractedFolder.FullName\* -Destination $InstallPath -Recurse -Force
            
            # Cleanup
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
            
            return $true
        }
        
        return $false
    }
    catch {
        Write-LogMessage "Failed to download PSADT 4.0: $($_.Exception.Message)" -Type "Error"
        return $false
    }
}
#endregion Helper Functions

#region Main Script
try {
    Write-LogMessage "Starting PSADT 4.0 setup..." -Type "Info"
    
    # Check if already installed and not forcing
    if ((Test-PSADT4Installation -Path $InstallPath) -and -not $ForceDownload) {
        Write-LogMessage "PSADT 4.0 is already installed at: $InstallPath" -Type "Success"
        Write-LogMessage "Use -ForceDownload to reinstall" -Type "Info"
        exit 0
    }
    
    # Create install directory
    if (!(Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-LogMessage "Created installation directory: $InstallPath" -Type "Info"
    }
    
    # Download and install PSADT 4.0
    $downloadSuccess = Download-PSADT4FromGitHub -InstallPath $InstallPath -Branch $Branch
    
    if ($downloadSuccess) {
        # Verify installation
        if (Test-PSADT4Installation -Path $InstallPath) {
            Write-LogMessage "PSADT 4.0 successfully installed!" -Type "Success"
            Write-LogMessage "Installation path: $InstallPath" -Type "Success"
            
            # Display version information
            $mainScript = Join-Path $InstallPath "Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1"
            $content = Get-Content $mainScript -Raw
            
            if ($content -match '\$appDeployToolkitVersion\s*=\s*\[version\]\s*[''"]([^''"]+)[''"]') {
                Write-LogMessage "PSADT Version: $($matches[1])" -Type "Info"
            }
            
            Write-LogMessage "`nNext steps:" -Type "Info"
            Write-LogMessage "1. Use New-PSADT4Package.ps1 to create packages" -Type "Info"
            Write-LogMessage "2. Template location: $InstallPath\Toolkit" -Type "Info"
        } else {
            Write-LogMessage "Installation verification failed" -Type "Error"
            exit 1
        }
    } else {
        Write-LogMessage "Failed to download PSADT 4.0" -Type "Error"
        Write-LogMessage "Manual installation steps:" -Type "Warning"
        Write-LogMessage "1. Go to: https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases" -Type "Info"
        Write-LogMessage "2. Download the latest 4.x release" -Type "Info"
        Write-LogMessage "3. Extract to: $InstallPath" -Type "Info"
        exit 1
    }
}
catch {
    Write-LogMessage "Setup failed: $($_.Exception.Message)" -Type "Error"
    exit 1
}
#endregion Main Script
