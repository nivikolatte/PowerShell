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
        "Source\Adobe",
        "Source\Microsoft", 
        "Source\Google",
        "Source\Mozilla",
        "Source\Other",
        
        # Generated packages
        "Packages",
        
        # Configuration files
        "Config",
        
        # Logs and reports
        "Logs",
        "Reports",
        
        # Templates and samples
        "Templates",
        
        # Testing and validation
        "Testing\Sandbox",
        "Testing\Results",
        
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
        "Batch-PSADT4Packages.ps1",
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

function New-ConfigurationTemplates {
    param([string]$BasePath)
    
    $configPath = Join-Path $BasePath "Config"
    
    Write-LogMessage "Creating configuration templates..." -Type "Info"
    
    # CSV Template
    $csvTemplate = @"
AppName,AppVersion,AppPublisher,SourcePath,InstallFile,InstallType,Architecture,Language
Adobe Acrobat Reader,24.002.20933,Adobe,$BasePath\Source\Adobe,AdobeReader.exe,EXE,x64,EN
Google Chrome,120.0.6099.129,Google,$BasePath\Source\Google,ChromeStandaloneSetup64.exe,EXE,x64,EN
Mozilla Firefox,121.0,Mozilla,$BasePath\Source\Mozilla,Firefox Setup 121.0.exe,EXE,x64,EN
Microsoft Visual C++ 2022 Redistributable,14.40.33810,Microsoft,$BasePath\Source\Microsoft,VC_redist.x64.exe,EXE,x64,EN
7-Zip,23.01,Igor Pavlov,$BasePath\Source\Other,7z2301-x64.msi,MSI,x64,EN
"@
    
    Set-Content -Path (Join-Path $configPath "AppList-Template.csv") -Value $csvTemplate -Encoding UTF8
    
    # JSON Template
    $jsonTemplate = @{
        "metadata" = @{
            "version" = "1.0"
            "created" = (Get-Date -Format "yyyy-MM-dd")
            "description" = "PSADT 4.0 Application Configuration Template"
            "basePath" = $BasePath
        }
        "defaults" = @{
            "architecture" = "x64"
            "language" = "EN"
            "outputPath" = "$BasePath\Packages"
            "psadt4Path" = "$BasePath\PSADT4"
        }
        "applications" = @(
            @{
                "appName" = "Adobe Acrobat Reader"
                "appVersion" = "24.002.20933"
                "appPublisher" = "Adobe"
                "sourcePath" = "$BasePath\Source\Adobe"
                "installFile" = "AdobeReader.exe"
                "installType" = "EXE"
                "architecture" = "x64"
                "language" = "EN"
                "priority" = 1
                "enabled" = $true
                "notes" = "Standard Adobe Reader deployment"
            },
            @{
                "appName" = "Google Chrome"
                "appVersion" = "120.0.6099.129"
                "appPublisher" = "Google"
                "sourcePath" = "$BasePath\Source\Google"
                "installFile" = "ChromeStandaloneSetup64.exe"
                "installType" = "EXE"
                "architecture" = "x64"
                "language" = "EN"
                "priority" = 2
                "enabled" = $true
                "notes" = "Enterprise Chrome deployment"
            }
        )
    } | ConvertTo-Json -Depth 4
    
    Set-Content -Path (Join-Path $configPath "AppList-Template.json") -Value $jsonTemplate -Encoding UTF8
    
    Write-LogMessage "Configuration templates created" -Type "Success"
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
`$Global:PSADTConfigPath = '$BasePath\Config'

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
    Write-Host "Config: `$Global:PSADTConfigPath" -ForegroundColor White
}

function Start-PSADTSetup {
    Write-Host "Setting up PSADT 4.0..." -ForegroundColor Green
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

function Start-PSADTBatch {
    param([string]`$ConfigFile)
    
    `$configFilePath = Join-Path `$Global:PSADTConfigPath `$ConfigFile
    & "`$Global:PSADTScriptsPath\Batch-PSADT4Packages.ps1" -ConfigFile `$configFilePath -OutputPath `$Global:PSADTPackagesPath -PSADT4Path `$Global:PSADT4Path
}

function Test-PSADTPackage {
    param(
        [string]`$PackageName,
        [string]`$ValidationLevel = "Standard"
    )
    
    `$packagePath = Join-Path `$Global:PSADTPackagesPath `$PackageName
    & "`$Global:PSADTScriptsPath\Test-PSADT4Package.ps1" -PackagePath `$packagePath -ValidationLevel `$ValidationLevel -OutputReport
}

# Display welcome message
Write-Host ""
Write-Host "=== PSADT 4.0 Automation Environment ===" -ForegroundColor Cyan
Write-Host "Profile loaded successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host "  Get-PSADTPaths       - Show all configured paths" -ForegroundColor White
Write-Host "  Start-PSADTSetup     - Download and setup PSADT 4.0" -ForegroundColor White
Write-Host "  New-PSADTPackage     - Create a single package" -ForegroundColor White
Write-Host "  Start-PSADTBatch     - Process multiple packages" -ForegroundColor White
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

1. **Load the PowerShell Profile**
   ```powershell
   . .\PSADT-Profile.ps1
   ```

2. **Setup PSADT 4.0**
   ```powershell
   Start-PSADTSetup
   ```

3. **Verify Paths**
   ```powershell
   Get-PSADTPaths
   ```

## Creating Your First Package

1. **Place installer files** in the appropriate Source subfolder
2. **Create a single package**:
   ```powershell
   New-PSADTPackage -AppName "Adobe Reader" -AppVersion "24.002.20933" -AppPublisher "Adobe" -InstallFile "AdobeReader.exe" -InstallType "EXE" -SourceFolder "Adobe"
   ```

3. **Validate the package**:
   ```powershell
   Test-PSADTPackage -PackageName "Adobe-AdobeReader-24.002.20933"
   ```

## Batch Processing

1. **Edit configuration file**: `Config\AppList-Template.csv` or `Config\AppList-Template.json`
2. **Process multiple apps**:
   ```powershell
   Start-PSADTBatch -ConfigFile "AppList-Template.csv"
   ```

## Folder Structure

- **Source\\**: Place installer files here, organized by vendor
- **Packages\\**: Generated PSADT packages appear here
- **Config\\**: Configuration files for batch processing
- **Logs\\**: Execution logs and error reports
- **Reports\\**: Validation reports
- **Testing\\**: Test results and sandbox environments

## Next Steps

1. Copy your installer files to the Source folders
2. Edit the configuration templates with your applications
3. Run batch processing for multiple applications
4. Use validation reports to ensure quality
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
│   ├── Batch-PSADT4Packages.ps1
│   └── Test-PSADT4Package.ps1
├── PSADT4\                     # PSADT 4.0 installation
│   └── Toolkit\
├── Source\                     # Source installer files
│   ├── Adobe\                  # Adobe products
│   ├── Microsoft\              # Microsoft products
│   ├── Google\                 # Google products
│   ├── Mozilla\                # Mozilla products
│   └── Other\                  # Other vendors
├── Packages\                   # Generated PSADT packages
├── Config\                     # Configuration files
│   ├── AppList-Template.csv
│   └── AppList-Template.json
├── Logs\                       # Execution logs
├── Reports\                    # Validation reports
├── Templates\                  # Custom templates
├── Testing\                    # Testing and validation
│   ├── Sandbox\
│   └── Results\
├── Documentation\              # Guides and documentation
├── PSADT-Profile.ps1          # PowerShell profile
└── README.md                  # Main documentation
```

## Folder Descriptions

### Scripts\
Contains all automation PowerShell scripts for PSADT 4.0 package creation and management.

### PSADT4\
Installation location for PowerShell App Deployment Toolkit 4.0. Automatically populated by Setup-PSADT4.ps1.

### Source\
Organized storage for installer files. Subfolders by vendor help maintain organization:
- Place .msi, .exe, .msp files here
- Maintain folder structure for batch processing
- Include any supporting files (transforms, patches, etc.)

### Packages\
Output location for generated PSADT packages. Each package gets its own subfolder with complete PSADT structure.

### Config\
Configuration files for batch processing. Templates provided for CSV and JSON formats.

### Logs\
Execution logs, error reports, and operational data from automation scripts.

### Reports\
Validation reports, package analysis, and quality assurance documentation.

### Testing\
Sandbox environments and test results for package validation and quality assurance.

## Best Practices

1. **Maintain vendor organization** in Source folders
2. **Use descriptive names** for configuration files
3. **Regular cleanup** of old packages and logs
4. **Version control** configuration files
5. **Document custom modifications** in Templates folder
"@
    
    Set-Content -Path (Join-Path $docsPath "FolderStructure.md") -Value $folderStructure -Encoding UTF8
    
    Write-LogMessage "Documentation files created" -Type "Success"
}

function New-SampleSourceFiles {
    param([string]$BasePath)
    
    if (-not $CreateSampleData) { return }
    
    Write-LogMessage "Creating sample source file structure..." -Type "Info"
    
    $sampleData = @{
        "Adobe" = @("AdobeReader.exe", "AdobeReader.msi", "transform.mst")
        "Microsoft" = @("VC_redist.x64.exe", "VC_redist.x86.exe", "Office365.exe")
        "Google" = @("ChromeStandaloneSetup64.exe", "ChromeStandaloneSetup32.exe")
        "Mozilla" = @("Firefox Setup.exe", "Thunderbird Setup.exe")
        "Other" = @("7z2301-x64.msi", "notepadplusplus.exe", "vlc-player.exe")
    }
    
    foreach ($vendor in $sampleData.GetEnumerator()) {
        $vendorPath = Join-Path $BasePath "Source\$($vendor.Key)"
        
        foreach ($file in $vendor.Value) {
            $filePath = Join-Path $vendorPath $file
            # Create empty placeholder files
            "# Placeholder for $file" | Set-Content -Path $filePath -Encoding UTF8
        }
        
        Write-LogMessage "Created sample files for: $($vendor.Key)" -Type "Success"
    }
    
    # Create a README in Source folder
    $sourceReadme = @"
# Source Files Directory

## Organization
Place your installer files in the appropriate vendor subdirectories:

- **Adobe\\**: Adobe products (Reader, Acrobat, Creative Suite, etc.)
- **Microsoft\\**: Microsoft products (Office, Visual C++, .NET, etc.)
- **Google\\**: Google products (Chrome, Earth, etc.)
- **Mozilla\\**: Mozilla products (Firefox, Thunderbird, etc.)
- **Other\\**: All other vendor products

## File Types Supported
- **.msi**: Windows Installer packages
- **.exe**: Executable installers
- **.msp**: Windows Installer patch files
- **.mst**: Transform files (place with corresponding MSI)

## Best Practices
1. Use descriptive filenames including version numbers
2. Keep supporting files (transforms, patches) with main installer
3. Test installers manually before automation
4. Document any special installation requirements

## Current Sample Files
$(if ($CreateSampleData) { "Sample placeholder files have been created for demonstration." } else { "Copy your real installer files here to begin automation." })
"@
    
    Set-Content -Path (Join-Path $BasePath "Source\README.md") -Value $sourceReadme -Encoding UTF8
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
    
    # Create configuration templates
    New-ConfigurationTemplates -BasePath $BasePath
    
    # Create PowerShell profile
    New-PowerShellProfile -BasePath $BasePath
    
    # Create documentation
    New-DocumentationFiles -BasePath $BasePath
    
    # Create sample source files if requested
    New-SampleSourceFiles -BasePath $BasePath
    
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
    Write-LogMessage "2. Load the profile: . .\PSADT-Profile.ps1" -Type "Info"
    Write-LogMessage "3. Run: Start-PSADTSetup" -Type "Info"
    Write-LogMessage "4. Copy installer files to Source folders" -Type "Info"
    Write-LogMessage "5. Edit Config templates with your applications" -Type "Info"
    Write-LogMessage "6. Start creating packages!" -Type "Info"
    
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
