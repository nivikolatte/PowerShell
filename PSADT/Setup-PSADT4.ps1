#Requires -Version 5.1
<#
.SYNOPSIS
    Validates PowerShell App Deployment Toolkit 4.0 installation

.DESCRIPTION
    This script validates that PSADT 4.0 has been manually installed at the specified path.
    It checks for required files and PSADT 4.0 compliance. No automatic download functionality.
    
    MANUAL INSTALLATION REQUIRED:
    1. Download PSADT 4.0 from: https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases
    2. Extract to the specified InstallPath
    3. Run this script to validate the installation

.PARAMETER InstallPath
    Installation path for PSADT 4.0 (default: C:\PSADT4)

.PARAMETER CreateGuide
    Creates a manual installation guide and exits

.EXAMPLE
    .\Setup-PSADT4.ps1

.EXAMPLE
    .\Setup-PSADT4.ps1 -InstallPath "D:\Tools\PSADT4"

.EXAMPLE
    .\Setup-PSADT4.ps1 -CreateGuide

.NOTES
    Author: IT Department
    Version: 2.0.0
    Date: 2025-06-14
    Requires: PowerShell 5.1+, Manual PSADT 4.0 installation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$InstallPath = "C:\PSADT4",
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateGuide
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
    
    # PSADT 4.0 has a different structure - check for the new files
    $requiredFiles = @(
        "Toolkit\Deploy-Application.ps1",
        "Toolkit\PSAppDeployToolkit.psd1",
        "Toolkit\PSAppDeployToolkit.psm1"
    )
    
    foreach ($file in $requiredFiles) {
        if (!(Test-Path (Join-Path $Path $file))) {
            Write-LogMessage "Missing required file: $file" -Type "Error"
            return $false
        }
    }
    
    # Check for PSADT 4.0 version in module manifest
    $manifestPath = Join-Path $Path "Toolkit\PSAppDeployToolkit.psd1"
    if (Test-Path $manifestPath) {
        $manifest = Import-PowerShellDataFile $manifestPath -ErrorAction SilentlyContinue
        if ($manifest.ModuleVersion -and $manifest.ModuleVersion.ToString().StartsWith("4.")) {
            Write-LogMessage "Found PSADT version: $($manifest.ModuleVersion)" -Type "Success"
            return $true
        }
    }
    
    Write-LogMessage "PSADT 4.0 version validation failed" -Type "Error"
    return $false
}
#endregion Helper Functions

#region Main Script
try {
    Write-LogMessage "Validating PSADT 4.0 installation..." -Type "Info"
    
    if ($CreateGuide) {
        Write-LogMessage "Creating manual installation guide..." -Type "Info"
        
        $guideContent = @"
# PSADT 4.0 Manual Installation Guide

## Steps to Install PSADT 4.0

1. **Download PSADT 4.0**
   - Go to: https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases
   - Download the latest PSADT 4.0 release (ZIP file)

2. **Extract to Installation Path**
   - Extract the ZIP file to: $InstallPath
   - Ensure the folder structure looks like:
     ```
     $InstallPath\
     └── Toolkit\
         ├── Deploy-Application.ps1
         ├── PSAppDeployToolkit.psd1
         ├── PSAppDeployToolkit.psm1
         └── en\
     ```

3. **Validate Installation**
   - Run this script again without -CreateGuide to validate
   - .\Setup-PSADT4.ps1 -InstallPath "$InstallPath"

## Notes
- This automation suite requires PSADT 4.0 or later
- Manual download ensures you get the exact version you need
- No automatic downloads are performed for security reasons
"@
        
        $guidePath = Join-Path (Split-Path $InstallPath -Parent) "PSADT4-Installation-Guide.md"
        Set-Content -Path $guidePath -Value $guideContent -Encoding UTF8
        Write-LogMessage "Installation guide created: $guidePath" -Type "Success"
        exit 0
    }
    
    # Check if PSADT 4.0 is manually installed
    if (Test-PSADT4Installation -Path $InstallPath) {
        Write-LogMessage "PSADT 4.0 installation validated!" -Type "Success"
        Write-LogMessage "Installation path: $InstallPath" -Type "Success"
        
        # Display version information
        $mainScript = Join-Path $InstallPath "Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1"
        $content = Get-Content $mainScript -Raw -ErrorAction SilentlyContinue
        
        if ($content -match '\$appDeployToolkitVersion\s*=\s*\[version\]\s*[''"]([^''"]+)[''"]') {
            Write-LogMessage "PSADT Version: $($matches[1])" -Type "Info"
        }
        
        Write-LogMessage "`nNext steps:" -Type "Info"
        Write-LogMessage "1. Use New-PSADT4Package.ps1 to create packages" -Type "Info"
        Write-LogMessage "2. Template location: $InstallPath\Toolkit" -Type "Info"
    } else {
        Write-LogMessage "PSADT 4.0 not found at: $InstallPath" -Type "Error"
        Write-LogMessage "`nTo install PSADT 4.0:" -Type "Info"
        Write-LogMessage "1. Download from: https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases" -Type "Info"
        Write-LogMessage "2. Extract to: $InstallPath" -Type "Info"
        Write-LogMessage "3. Run this script again to validate" -Type "Info"
        Write-LogMessage "`nOr create installation guide: .\Setup-PSADT4.ps1 -CreateGuide" -Type "Info"
        exit 1
    }
}
catch {
    Write-LogMessage "Validation failed: $($_.Exception.Message)" -Type "Error"
    exit 1
}
#endregion Main Script
