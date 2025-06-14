# PSADT 4.0 Automation Suite

A comprehensive automation solution for creating, validating, and managing PowerShell App Deployment Toolkit 4.0 packages. This suite eliminates repetitive tasks and ensures consistent, high-quality package creation following PSADT 4.0 best practices.

## 🚀 Features

- **PSADT 4.0 Compliant**: Updated for latest PSADT 4.0 standards and best practices
- **Automated Package Creation**: Generate complete PSADT packages from minimal input
- **Batch Processing**: Create multiple packages from CSV/JSON configuration
- **Comprehensive Validation**: Multi-level package validation and testing
- **Modern PowerShell**: PowerShell 5.1+ with proper error handling and logging
- **Security Focused**: Built-in security compliance checks
- **Enterprise Ready**: Parallel processing, detailed logging, and reporting

## 📁 Components

### Core Scripts

| Script | Purpose | Description |
|--------|---------|-------------|
| `Setup-PSADT4.ps1` | Setup | Downloads and configures PSADT 4.0 |
| `New-PSADT4Package.ps1` | Creation | Creates individual PSADT packages |
| `Batch-PSADT4Packages.ps1` | Batch Processing | Processes multiple apps from configuration |
| `Test-PSADT4Package.ps1` | Validation | Validates package compliance and quality |

## 🛠️ Quick Start

### 1. Initialize Folder Structure (Recommended)

```powershell
# Create organized folder structure
.\Initialize-PSADTStructure.ps1

# Or create with sample data for testing
.\Initialize-PSADTStructure.ps1 -BasePath "C:\PSADT_Automation" -CreateSampleData

# Load the PowerShell profile (from the created structure)
cd C:\PSADT_Automation
. .\PSADT-Profile.ps1
```

### 2. Initial Setup

```powershell
# Download and setup PSADT 4.0 (using profile function)
Start-PSADTSetup

# Or run directly
.\Scripts\Setup-PSADT4.ps1 -InstallPath "C:\PSADT_Automation\PSADT4"
```

### 3. Create Single Package

```powershell
# Using profile helper function (after copying installer to Source\Adobe\)
New-PSADTPackage -AppName "Adobe Reader" -AppVersion "24.002.20933" -AppPublisher "Adobe" -InstallFile "AdobeReader.exe" -InstallType "EXE" -SourceFolder "Adobe"

# Or run script directly
.\Scripts\New-PSADT4Package.ps1 -AppName "Adobe Reader" -AppVersion "24.002.20933" -AppPublisher "Adobe" -SourcePath "C:\PSADT_Automation\Source\Adobe" -InstallFile "AdobeReader.exe" -InstallType "EXE"
```

### 4. Batch Processing

```powershell
# Edit Config\AppList-Template.csv or Config\AppList-Template.json first

# Using profile helper function
Start-PSADTBatch -ConfigFile "AppList-Template.csv"

# Or run script directly
.\Scripts\Batch-PSADT4Packages.ps1 -ConfigFile "C:\PSADT_Automation\Config\AppList-Template.csv"
```

### 5. Package Validation

```powershell
# Using profile helper function
Test-PSADTPackage -PackageName "Adobe-AdobeReader-24.002.20933" -ValidationLevel "Comprehensive"

# Or run script directly
.\Scripts\Test-PSADT4Package.ps1 -PackagePath "C:\PSADT_Automation\Packages\Adobe-AdobeReader-24.002.20933" -ValidationLevel Comprehensive -OutputReport
```

## 📁 Recommended Folder Structure

Use the `Initialize-PSADTStructure.ps1` script to create this organized structure:

```
C:\PSADT_Automation\
├── Scripts\                    # Automation PowerShell scripts
│   ├── Setup-PSADT4.ps1
│   ├── New-PSADT4Package.ps1
│   ├── Batch-PSADT4Packages.ps1
│   └── Test-PSADT4Package.ps1
├── PSADT4\                     # PSADT 4.0 installation
│   └── Toolkit\
├── Source\                     # Source installer files (organized by vendor)
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
├── Testing\                    # Testing and validation
├── Documentation\              # Guides and documentation
├── PSADT-Profile.ps1          # PowerShell profile with helper functions
└── README.md                  # Main documentation
```

## 📋 Configuration Formats

### CSV Configuration

```csv
AppName,AppVersion,AppPublisher,SourcePath,InstallFile,InstallType,Architecture,Language
Adobe Acrobat Reader,24.002.20933,Adobe,C:\Source\Adobe,AdobeReader.exe,EXE,x64,EN
7-Zip,23.01,Igor Pavlov,C:\Source\7Zip,7z2301-x64.msi,MSI,x64,EN
Notepad++,8.5.8,Don Ho,C:\Source\NotepadPlusPlus,npp.8.5.8.Installer.x64.exe,EXE,x64,EN
```

### JSON Configuration

```json
{
  "metadata": {
    "version": "1.0",
    "created": "2025-06-14",
    "description": "PSADT 4.0 Application Configuration"
  },
  "defaults": {
    "architecture": "x64",
    "language": "EN",
    "outputPath": "C:\\PSADT_Packages"
  },
  "applications": [
    {
      "appName": "Adobe Acrobat Reader",
      "appVersion": "24.002.20933",
      "appPublisher": "Adobe",
      "sourcePath": "C:\\Source\\Adobe",
      "installFile": "AdobeReader.exe",
      "installType": "EXE",
      "architecture": "x64",
      "language": "EN",
      "priority": 1,
      "enabled": true
    }
  ]
}
```

## 🎯 PSADT 4.0 Compliance

### Generated Scripts Include:

- ✅ **PowerShell 5.1+ Requirement**: `#Requires -Version 5.1`
- ✅ **Modern Parameter Validation**: Proper CmdletBinding and validation
- ✅ **Standard Parameters**: DeploymentType, DeployMode, AllowRebootPassThru
- ✅ **Comprehensive Error Handling**: Try/Catch blocks with proper logging
- ✅ **PSADT 4.0 Functions**: Updated function calls and parameters
- ✅ **Security Best Practices**: Execution policy handling and safe coding
- ✅ **Proper Variable Scope**: Application and script variables properly scoped
- ✅ **Documentation Standards**: Help documentation and comments

### Template Features:

```powershell
# Example generated Deploy-Application.ps1 structure
#Requires -Version 5.1
[CmdletBinding()]
Param (
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]$DeploymentType = 'Install',
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'Interactive',
    [Switch]$AllowRebootPassThru = $false
)

Try {
    # Application variables following PSADT 4.0 standards
    [String]$appVendor = 'Adobe'
    [String]$appName = 'Adobe Reader'
    [String]$appVersion = '24.002.20933'
    
    # Proper toolkit initialization
    . "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
    
    # Installation logic with proper error handling
    If ($deploymentType -ine 'Uninstall') {
        Show-InstallationWelcome -CloseApps 'AdobeReader' -CheckDiskSpace
        Execute-Process -Path $InstallFile -Parameters '/S'
    }
}
Catch {
    # Comprehensive error handling
    [Int32]$mainExitCode = 60001
    Write-Log -Message $mainErrorMessage -Severity 3
    Exit-Script -ExitCode $mainExitCode
}
```

## 🔍 Validation Levels

### Basic Validation
- File structure verification
- PowerShell syntax checking
- Required file presence

### Standard Validation
- PSADT 4.0 compliance checks
- Security compliance scanning
- Best practices verification

### Comprehensive Validation
- Installation simulation
- Advanced security checks
- Performance analysis
- Detailed reporting

## 📊 Reporting

### Validation Reports
- HTML reports with detailed results
- Pass/Fail/Warning categorization
- Actionable recommendations
- Security compliance status

### Batch Processing Logs
- Detailed execution logs
- Success/failure tracking
- Performance metrics
- Error analysis

## 🔧 Advanced Usage

### Custom Templates

Modify the `New-PSADT4DeployScript` function in `New-PSADT4Package.ps1` to customize:
- Install parameters by vendor
- Detection logic patterns
- Error handling strategies
- Post-installation tasks

### Enterprise Integration

```powershell
# Integration with CI/CD pipelines
$apps = Import-Csv "\\share\configs\monthly-updates.csv"
.\Batch-PSADT4Packages.ps1 -ConfigFile $apps -MaxConcurrentJobs 10 -LogPath "\\logs\psadt"

# Automated validation in deployment pipeline
$validationResult = .\Test-PSADT4Package.ps1 -PackagePath $packagePath -ValidationLevel Comprehensive
if ($LASTEXITCODE -eq 0) {
    # Deploy to Intune/SCCM
    & IntuneWinAppUtil.exe -c $packagePath -s "Deploy-Application.ps1" -o $outputPath
}
```

### Custom Vendor Patterns

Add vendor-specific logic to the script generator:

```powershell
# Add to New-PSADT4DeployScript function
$vendorDefaults = @{
    'Adobe' = @{
        InstallParams = '/sAll /rs /msi EULA_ACCEPT=YES'
        ProcessName = 'AcroRd32'
    }
    'Microsoft' = @{
        InstallParams = '/quiet /norestart'
        ProcessName = $AppName -replace '\s',''
    }
}
```

## 🚀 Best Practices

### Package Creation
1. **Test locally** before deployment
2. **Use validation** at multiple levels
3. **Follow naming conventions** for consistency
4. **Include proper documentation** in scripts
5. **Validate source files** before processing

### Security
1. **Sign PowerShell scripts** for production
2. **Validate digital signatures** on installer files
3. **Use least privilege** for installation accounts
4. **Audit installation logs** regularly
5. **Test in isolated environments** first

### Performance
1. **Use parallel processing** for batch operations
2. **Optimize source file organization**
3. **Monitor disk space** during operations
4. **Clean up temporary files** automatically
5. **Log performance metrics** for optimization

## 📝 Requirements

- **PowerShell 5.1 or later**
- **PSADT 4.0** (automatically downloaded by Setup-PSADT4.ps1)
- **Administrator privileges** for package testing
- **Internet connection** for PSADT 4.0 download
- **Sufficient disk space** for package creation and logs

## 🎯 Migration from PSADT 3.x

The automation suite is designed specifically for PSADT 4.0. Key differences from 3.x:

1. **PowerShell 5.1 Requirement**: Updated minimum version
2. **Modern Parameter Handling**: Improved validation and binding
3. **Enhanced Error Handling**: Better exception management
4. **Security Improvements**: Updated security practices
5. **Function Updates**: Latest PSADT function calls and parameters

## 🤝 Contributing

To enhance the automation suite:

1. **Fork the repository**
2. **Create feature branches** for enhancements
3. **Test thoroughly** with multiple package types
4. **Update documentation** for new features
5. **Submit pull requests** with detailed descriptions

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

#### PSADT 4.0 Not Found
```powershell
# Solution: Run setup script
.\Setup-PSADT4.ps1 -ForceDownload
```

#### Package Validation Fails
```powershell
# Solution: Check detailed validation report
.\Test-PSADT4Package.ps1 -PackagePath $path -ValidationLevel Comprehensive -OutputReport
```

#### Batch Processing Errors
```powershell
# Solution: Check configuration file format and paths
.\Batch-PSADT4Packages.ps1 -CreateSampleConfig
```

### Getting Help

1. **Check validation reports** for specific issues
2. **Review log files** in the specified log directory
3. **Verify source file paths** and permissions
4. **Ensure PSADT 4.0** is properly installed
5. **Test with single packages** before batch processing

## 📞 Support

For issues and questions:
- **Internal Support**: Contact IT Department
- **Documentation**: Review PSADT 4.0 official documentation
- **Community**: PowerShell App Deployment Toolkit community forums

---

*Generated on 2025-06-14 | PSADT 4.0 Automation Suite v2.0.0*
