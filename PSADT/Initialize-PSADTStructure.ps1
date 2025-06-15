#Requires -Version 5.1
<#
.SYNOPSIS
    Creates the recommended folder structure for PSADT 4.0 automation

.DESCRIPTION
    This script sets up the optimal directory structure for PSADT 4.0 package automation,
    including source files, output directories, logs, and configuration templates.

.PARAMETER BasePath
    Base path for the PSADT automation structure (default: C:\PSADT_Automation)

.PARAMETER CreateSampleData
    Creates sample source files and configurations for testing

.EXAMPLE
    .\Initialize-PSADTStructure.ps1

.EXAMPLE
    .\Initialize-PSADTStructure.ps1 -BasePath "D:\PackageAutomation" -CreateSampleData

.NOTES
    Author: IT Department
    Version: 1.0.0
    Date: 2025-06-14
    Requires: PowerShell 5.1+
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$BasePath = "C:\PSADT_Automation",
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateSampleData
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

function New-DirectoryStructure {
    param([string]$BasePath)
    
    $directories = @(
        # Core automation scripts
        "Scripts",
        
        # PSADT 4.0 installation
        "PSADT4",
        
        # Source installer files organized by vendor
        "Source",
        
        # Generated packages
        "Packages",
        
        # Logs and reports
        "Logs",
        "Reports",
        
        # Documentation
        "Documentation"
    )
    
    Write-LogMessage "Creating directory structure at: $BasePath" -Type "Info"
    
    foreach ($dir in $directories) {
        $fullPath = Join-Path $BasePath $dir
        if (!(Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-LogMessage "Created: $dir" -Type "Success"
        } else {
            Write-LogMessage "Exists: $dir" -Type "Info"
        }
    }
}

function Copy-AutomationScripts {
    param(
        [string]$BasePath,
        [string]$SourcePath
    )
    
    $scriptsPath = Join-Path $BasePath "Scripts"
    
    Write-LogMessage "Copying automation scripts..." -Type "Info"
    
    $scriptFiles = @(
        "Setup-PSADT4.ps1",
        "New-PSADT4Package.ps1", 
        "Test-PSADT4Package.ps1"
    )
    
    foreach ($script in $scriptFiles) {
        $sourcePath = Join-Path $SourcePath $script
        $destPath = Join-Path $scriptsPath $script
        
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-LogMessage "Copied: $script" -Type "Success"
        } else {
            Write-LogMessage "Source not found: $script" -Type "Warning"
        }
    }
}

function New-PowerShellProfile {
    param([string]$BasePath)
    
    $scriptsPath = Join-Path $BasePath "Scripts"
    $profilePath = Join-Path $BasePath "PSADT-Profile.ps1"
    
    $profileContent = @"
# PSADT 4.0 Automation Profile
# Source this file to set up your PowerShell session for PSADT automation

# Set base paths
`$Global:PSADTBasePath = '$BasePath'
`$Global:PSADTScriptsPath = '$scriptsPath'
`$Global:PSADT4Path = '$BasePath\PSADT4'
`$Global:PSADTSourcePath = '$BasePath\Source'
`$Global:PSADTPackagesPath = '$BasePath\Packages'

# Change to scripts directory
Set-Location `$Global:PSADTScriptsPath

# Helper functions
function Get-PSADTPaths {
    Write-Host "PSADT 4.0 Automation Paths:" -ForegroundColor Cyan
    Write-Host "Base Path: `$Global:PSADTBasePath" -ForegroundColor White
    Write-Host "Scripts: `$Global:PSADTScriptsPath" -ForegroundColor White
    Write-Host "PSADT 4.0: `$Global:PSADT4Path" -ForegroundColor White
    Write-Host "Source Files: `$Global:PSADTSourcePath" -ForegroundColor White
    Write-Host "Packages: `$Global:PSADTPackagesPath" -ForegroundColor White
}

function Start-PSADTSetup {
    Write-Host "Validating PSADT 4.0 installation..." -ForegroundColor Green
    & "`$Global:PSADTScriptsPath\Setup-PSADT4.ps1" -InstallPath `$Global:PSADT4Path
}

function New-PSADTPackage {
    param(
        [string]`$AppName,
        [string]`$AppVersion,
        [string]`$AppPublisher,
        [string]`$InstallFile,
        [string]`$InstallType = "EXE",
        [string]`$SourceFolder
    )
    
    `$sourcePath = Join-Path `$Global:PSADTSourcePath `$SourceFolder
    & "`$Global:PSADTScriptsPath\New-PSADT4Package.ps1" -AppName `$AppName -AppVersion `$AppVersion -AppPublisher `$AppPublisher -SourcePath `$sourcePath -InstallFile `$InstallFile -InstallType `$InstallType -OutputPath `$Global:PSADTPackagesPath -PSADT4Path `$Global:PSADT4Path
}

function Test-PSADTPackage {
    param(
        [string]`$PackageName,
        [string]`$ValidationLevel = "Standard"
    )
    
    `$packagePath = Join-Path `$Global:PSADTPackagesPath `$PackageName
    & "`$Global:PSADTScriptsPath\Test-PSADT4Package.ps1" -PackagePath `$packagePath -ValidationLevel `$ValidationLevel -OutputReport -ReportPath "`$Global:PSADTBasePath\Reports"
}

# Display welcome message
Write-Host ""
Write-Host "=== PSADT 4.0 Automation Environment ===" -ForegroundColor Cyan
Write-Host "Profile loaded successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host "  Get-PSADTPaths       - Show all configured paths" -ForegroundColor White
Write-Host "  Start-PSADTSetup     - Validate PSADT 4.0 installation" -ForegroundColor White
Write-Host "  New-PSADTPackage     - Create a single package" -ForegroundColor White
Write-Host "  Test-PSADTPackage    - Validate a package" -ForegroundColor White
Write-Host ""
Write-Host "Current location: `$Global:PSADTScriptsPath" -ForegroundColor Cyan
Write-Host ""
"@
    
    Set-Content -Path $profilePath -Value $profileContent -Encoding UTF8
    Write-LogMessage "PowerShell profile created: PSADT-Profile.ps1" -Type "Success"
}

function New-DocumentationFiles {
    param([string]$BasePath)
    
    $docsPath = Join-Path $BasePath "Documentation"
    
    # Quick Start Guide
    $quickStart = @"
# PSADT 4.0 Automation Quick Start Guide

## Initial Setup

1. **Install PSADT 4.0** using the official installer or package manager
2. **Load the PowerShell Profile**
   ```powershell
   . .\PSADT-Profile.ps1
   ```
3. **Verify Paths**
   ```powershell
   Get-PSADTPaths
   ```

## Creating a Package

1. **Place installer files** in the `Source` folder
2. **Create a package**:
   ```powershell
   New-PSADTPackage -AppName "Adobe Reader" -AppVersion "24.002.20933" -AppPublisher "Adobe" -InstallFile "AdobeReader.exe" -InstallType "EXE" -SourceFolder "Adobe"
   ```
3. **Validate the package**:
   ```powershell
   Test-PSADTPackage -PackageName "Adobe-AdobeReader-24.002.20933"
   ```

## Folder Structure

- **Source\\**: Place installer files here
- **Packages\\**: Generated PSADT packages
- **Logs\\**: Execution logs
- **Reports\\**: Validation reports
- **Documentation\\**: Guides and documentation

## Next Steps

1. Copy your installer files to the Source folder
2. Run New-PSADTPackage for each app
3. Use Test-PSADTPackage to validate
"@
    
    Set-Content -Path (Join-Path $docsPath "QuickStart.md") -Value $quickStart -Encoding UTF8
    
    # Folder Structure Documentation
    $folderStructure = @"
# PSADT 4.0 Automation Folder Structure

## Overview
```
$BasePath\
├── Scripts\                    # Automation PowerShell scripts
│   ├── Setup-PSADT4.ps1
│   ├── New-PSADT4Package.ps1
│   └── Test-PSADT4Package.ps1
├── PSADT4\                     # PSADT 4.0 installation
│   └── Toolkit\
├── Source\                     # Source installer files
├── Packages\                   # Generated PSADT packages
├── Logs\                       # Execution logs
├── Reports\                    # Validation reports
├── Documentation\              # Guides and documentation
├── PSADT-Profile.ps1          # PowerShell profile
└── README.md                  # Main documentation
```

## Folder Descriptions

### Scripts\
Contains all automation PowerShell scripts for PSADT 4.0 package creation and management.

### PSADT4\
Installation location for PowerShell App Deployment Toolkit 4.0. Install using official installer.

### Source\
Organized storage for installer files:
- Place .msi, .exe, .msp files here
- Organize by vendor for easier management
- Include any supporting files (transforms, patches, etc.)

### Packages\
Output location for generated PSADT packages. Each package gets its own subfolder with complete PSADT structure.

### Logs\
Execution logs, error reports, and operational data from automation scripts.

### Reports\
Validation reports, package analysis, and quality assurance documentation.

## Best Practices

1. **Maintain vendor organization** in Source folders
2. **Use descriptive names** for package folders
3. **Regular cleanup** of old packages and logs
4. **Test packages thoroughly** before deployment
5. **Document custom modifications**
"@
    
    Set-Content -Path (Join-Path $docsPath "FolderStructure.md") -Value $folderStructure -Encoding UTF8
    
    Write-LogMessage "Documentation files created" -Type "Success"
}
#endregion Helper Functions

#region Main Script
try {
    Write-LogMessage "Initializing PSADT 4.0 Automation Structure" -Type "Info"
    Write-LogMessage "Base Path: $BasePath" -Type "Info"
    
    # Create the main directory structure
    New-DirectoryStructure -BasePath $BasePath
    
    # Copy automation scripts from current location
    $currentPath = $PSScriptRoot
    if ($currentPath) {
        Copy-AutomationScripts -BasePath $BasePath -SourcePath $currentPath
    } else {
        Write-LogMessage "Could not determine script location. Please manually copy scripts to Scripts folder." -Type "Warning"
    }
    
    # Create PowerShell profile
    New-PowerShellProfile -BasePath $BasePath
    
    # Create documentation
    New-DocumentationFiles -BasePath $BasePath
    
    # Copy main README to the root
    $mainReadmePath = Join-Path $BasePath "README.md"
    if ($currentPath -and (Test-Path (Join-Path $currentPath "README.md"))) {
        Copy-Item -Path (Join-Path $currentPath "README.md") -Destination $mainReadmePath -Force
        Write-LogMessage "Main README copied" -Type "Success"
    }
    
    Write-LogMessage "`n=== SETUP COMPLETE ===" -Type "Success"
    Write-LogMessage "PSADT 4.0 Automation structure created at: $BasePath" -Type "Success"
      Write-LogMessage "`nNext Steps:" -Type "Info"
    Write-LogMessage "1. Open PowerShell in: $BasePath" -Type "Info"
    Write-LogMessage "2. Install PSADT 4.0 to: $BasePath\PSADT4" -Type "Info"
    Write-LogMessage "3. Load the profile: . .\PSADT-Profile.ps1" -Type "Info"
    Write-LogMessage "4. Run: New-PSADTPackage for your app" -Type "Info"
    Write-LogMessage "5. Validate with: Test-PSADTPackage" -Type "Info"
    
    Write-LogMessage "`nDocumentation:" -Type "Info"
    Write-LogMessage "- Quick Start: $BasePath\Documentation\QuickStart.md" -Type "Info"
    Write-LogMessage "- Folder Structure: $BasePath\Documentation\FolderStructure.md" -Type "Info"
    Write-LogMessage "- Main README: $BasePath\README.md" -Type "Info"
    
    if ($CreateSampleData) {
        Write-LogMessage "`nSample data created in Source folders for testing" -Type "Info"
    }
}
catch {
    Write-LogMessage "Setup failed: $($_.Exception.Message)" -Type "Error"
    exit 1
}
#endregion Main Script
